from flask import Flask, request, jsonify, send_file
import json
import pyproj
from shapely.geometry import shape, mapping
from shapely.ops import transform
from io import StringIO

app = Flask(__name__)

@app.route('/convert', methods=['POST'])
def convert_geojson():
    data = request.get_json()
    geojson_data = data['geojson']

    # Define projections (example for UTM zone 33N)
    utm_proj = pyproj.CRS('EPSG:22332')
    wgs84_proj = pyproj.CRS('EPSG:4326')

    # Transform coordinates
    project = pyproj.Transformer.from_crs(utm_proj, wgs84_proj, always_xy=True).transform

    for feature in geojson_data['features']:
        geom = shape(feature['geometry'])
        geom_wgs84 = transform(project, geom)
        feature['geometry'] = mapping(geom_wgs84)

    # Save converted GeoJSON to memory
    output = StringIO()
    json.dump(geojson_data, output, indent=4)
    output.seek(0)

    return send_file(
        StringIO(output.getvalue()),
        mimetype='application/json',
        as_attachment=True,
        attachment_filename='converted.geojson'
    )

if __name__ == '__main__':
    app.run(debug=True)
