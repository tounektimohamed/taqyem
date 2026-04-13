import base64
import io
import json
import time
from functools import wraps

import jsonschema
import requests
from flask import Flask, request, jsonify
from PIL import Image, ImageFilter

app = Flask(__name__)

OPENROUTER_API_KEY = "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"
OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = "google/gemini-flash-1.5"

ALLOWED_MIME = {'image/jpeg', 'image/png', 'image/webp'}
MAX_SIZE_BYTES = 5 * 1024 * 1024
RATE_LIMIT_REQUESTS = 10
RATE_LIMIT_WINDOW = 60

rate_limit_store = {}

BAREMES_SCHEMA = {
    "type": "object",
    "required": ["baremes", "extraction_confidence"],
    "properties": {
        "baremes": {
            "type": "array",
            "minItems": 1,
            "maxItems": 10,
            "items": {
                "type": "object",
                "required": ["position", "name", "scores", "confidence"],
                "properties": {
                    "position": {"type": "integer", "minimum": 0},
                    "name": {"type": "string", "minLength": 1},
                    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                    "scores": {
                        "type": "object",
                        "required": ["---", "+--", "++-", "+++"],
                        "properties": {
                            "---": {"type": "number", "minimum": -1},
                            "+--": {"type": "number", "minimum": -1},
                            "++-": {"type": "number", "minimum": -1},
                            "+++": {"type": "number", "minimum": -1}
                        }
                    }
                }
            }
        },
        "extraction_confidence": {"type": "number", "minimum": 0, "maximum": 1}
    }
}

SYSTEM_PROMPT = """You are a specialized OCR system for Tunisian Arabic school grading tables
(جدول إسناد الأعداد). Your output will be parsed programmatically.

TASK: Extract all grading criteria and their score values from this image.

TABLE STRUCTURE:
- Arabic grading tables have criteria as columns (right to left)
- 4 evaluation levels as rows: "---" (lowest) → "+--" → "++-" → "+++" (highest)
- Some criteria may have sub-thresholds (عتبة 1, عتبة 2)
- Scores are decimal numbers (e.g., 0, 1.5, 2, 3, 4.5)

OUTPUT FORMAT — Return ONLY this JSON, nothing else:
{
  "baremes": [
    {
      "position": 0,
      "name": "exact Arabic name from table",
      "max": highest_numeric_score,
      "confidence": 0.95,
      "scores": {
        "---": 0,
        "+--": numeric_value,
        "++-": numeric_value,
        "+++": numeric_value
      },
      "has_sub_thresholds": false,
      "raw_cell_values": ["0", "1.5", "3", "4.5"]
    }
  ],
  "total_max": sum_of_all_max_scores,
  "extraction_confidence": 0.90,
  "notes": "any ambiguity or warning"
}

STRICT RULES:
1. position starts at 0, right-to-left order
2. All score values must be float numbers, never strings
3. If cell is empty or "—": infer from pattern (arithmetic progression)
4. If criterion has عتبة 1 & عتبة 2: use عتبة 2 for "+--" and "++-"
5. confidence per barème: 1.0=clear, 0.7=inferred, 0.5=uncertain
6. Never fabricate data — if truly unreadable, set score to -1
7. max = the "+++" score value for that criterion"""


def rate_limit_key():
    return request.headers.get('Authorization', 'anonymous')


def check_rate_limit():
    key = rate_limit_key()
    now = time.time()
    window_start = now - RATE_LIMIT_WINDOW
    
    if key not in rate_limit_store:
        rate_limit_store[key] = []
    
    rate_limit_store[key] = [t for t in rate_limit_store[key] if t > window_start]
    
    if len(rate_limit_store[key]) >= RATE_LIMIT_REQUESTS:
        return False
    
    rate_limit_store[key].append(now)
    return True


def preprocess_image(base64_str: str) -> str:
    try:
        img_data = base64.b64decode(base64_str)
    except Exception:
        return None
    
    if len(img_data) > MAX_SIZE_BYTES:
        return None
    
    try:
        img = Image.open(io.BytesIO(img_data))
    except Exception:
        return None
    
    if img.mode == 'RGBA':
        background = Image.new('RGB', img.size, (255, 255, 255))
        background.paste(img, mask=img.split()[3])
        img = background
    elif img.mode != 'RGB':
        img = img.convert('RGB')
    
    max_dim = 1600
    width, height = img.size
    if width > max_dim or height > max_dim:
        ratio = min(max_dim / width, max_dim / height)
        new_size = (int(width * ratio), int(height * ratio))
        img = img.resize(new_size, Image.Resampling.LANCZOS)
    
    from PIL import ImageEnhance
    enhancer = ImageEnhance.Sharpness(img)
    img = enhancer.enhance(1.5)
    
    img_gray = img.convert('L')
    img = Image.merge('RGB', [img_gray, img_gray, img_gray])
    
    output = io.BytesIO()
    img.save(output, format='JPEG', quality=85)
    return base64.b64encode(output.getvalue()).decode('utf-8')


def validate_and_sanitize(data: dict) -> tuple:
    warnings = []
    
    try:
        jsonschema.validate(data, BAREMES_SCHEMA)
    except jsonschema.ValidationError as e:
        return None, [f"schema_validation_failed: {str(e)}"]
    
    validated_baremes = []
    total = 0.0
    
    for bareme in data.get('baremes', []):
        scores = bareme.get('scores', {})
        
        if scores['---'] > scores['+--'] or scores['+--'] > scores['++-'] or scores['++-'] > scores['+++']:
            warnings.append(f"Score order issue in '{bareme.get('name', '')}'")
        
        if any(s == -1 for s in scores.values()):
            warnings.append(f"Unreadable score in '{bareme.get('name', '')}'")
        
        max_score = scores.get('+++', 0)
        total += max_score
        
        validated_baremes.append({
            'position': bareme.get('position', 0),
            'name': bareme.get('name', ''),
            'confidence': bareme.get('confidence', 0.5),
            'scores': {
                '---': scores.get('---', 0),
                '+--': scores.get('+--', 0),
                '++-': scores.get('++-', 0),
                '+++': scores.get('+++', 0)
            },
            'max': max_score,
            'has_sub_thresholds': bareme.get('has_sub_thresholds', False),
            'raw_cell_values': bareme.get('raw_cell_values', [])
        })
    
    if total < 5 or total > 40:
        warnings.append(f"Total max score ({total}) outside typical range (5-40)")
    
    return {
        'baremes': validated_baremes,
        'total_max': total,
        'extraction_confidence': data.get('extraction_confidence', 0.5)
    }, warnings


def call_openrouter(image_base64: str) -> dict:
    headers = {
        "Authorization": f"Bearer {OPENROUTER_API_KEY}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": OPENROUTER_MODEL,
        "messages": [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": SYSTEM_PROMPT},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}}
                ]
            }
        ]
    }
    
    response = requests.post(
        OPENROUTER_API_URL,
        headers=headers,
        json=payload,
        timeout=60
    )
    
    if response.status_code != 200:
        raise Exception(f"OpenRouter API error: {response.status_code}")
    
    result = response.json()
    content = result['choices'][0]['message']['content']
    
    if content.startswith('```json'):
        content = content[7:]
    if content.endswith('```'):
        content = content[:-3]
    
    return json.loads(content.strip())


@app.route('/ocr-grading-table', methods=['POST'])
def ocr_grading_table():
    start_time = time.time()
    
    if not check_rate_limit():
        return jsonify({"error": "rate_limit", "retry_after": RATE_LIMIT_WINDOW}), 429
    
    if 'Authorization' not in request.headers:
        return jsonify({"error": "unauthorized"}), 401
    
    data = request.get_json()
    if not data or 'image' not in data:
        return jsonify({"error": "invalid_image", "detail": "No image provided"}), 400
    
    try:
        processed_image = preprocess_image(data['image'])
        if processed_image is None:
            return jsonify({"error": "invalid_image", "detail": "Could not process image"}), 400
    except Exception as e:
        return jsonify({"error": "image_too_large", "max_kb": 5120}), 400
    
    try:
        ocr_result = call_openrouter(processed_image)
    except json.JSONDecodeError as e:
        return jsonify({"error": "json_parse_failed", "raw": str(e)[:200]}), 422
    except Exception as e:
        return jsonify({"error": "openrouter_error", "detail": str(e)}), 500
    
    if 'baremes' not in ocr_result or not ocr_result.get('baremes'):
        return jsonify({"error": "no_baremes_found", "detail": "No grading criteria found in image"}), 400
    
    validated_data, warnings = validate_and_sanitize(ocr_result)
    if validated_data is None:
        return jsonify({"error": "schema_validation_failed", "detail": warnings}), 422
    
    elapsed = int((time.time() - start_time) * 1000)
    image_size_kb = len(base64.b64decode(data['image'])) // 1024
    
    return jsonify({
        "success": True,
        "data": {
            "baremes": validated_data['baremes'],
            "total_max": validated_data['total_max'],
            "extraction_confidence": validated_data['extraction_confidence'],
            "warnings": warnings
        },
        "meta": {
            "model": OPENROUTER_MODEL,
            "processing_time_ms": elapsed,
            "image_size_kb": image_size_kb
        }
    })


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7860, debug=True)