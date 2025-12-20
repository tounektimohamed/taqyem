const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
admin.initializeApp();

// Dictionnaire de traduction
const TRANSLATIONS = {
  'ar': {
    'title': 'تقرير النتائج',
    'professor': 'الأستاذ',
    'subject': 'المادة',
    'class': 'القسم',
    'school': 'المؤسسة',
    'main_title': 'الجدول الجامع للنتائج',
    'student_name': 'الاسم واللقب',
    'achieved_students': 'عدد التلاميذ المحققين',
    'percentage': 'النسبة المئوية',
    'print_button': 'طباعة التقرير',
    'generated_by': 'تم إنشاء التقرير بواسطة نظام تقييم',
    'unknown': 'غير معروف',
    'no_data': 'لا توجد بيانات'
  },
  'fr': {
    'title': 'Rapport des Résultats',
    'professor': 'Professeur',
    'subject': 'Matière',
    'class': 'Classe',
    'school': 'Établissement',
    'main_title': 'Tableau Global des Résultats',
    'student_name': 'Nom et Prénom',
    'achieved_students': 'Nombre d\'élèves ayant atteint',
    'percentage': 'Pourcentage',
    'print_button': 'Imprimer le Rapport',
    'generated_by': 'Rapport généré par le système d\'évaluation',
    'unknown': 'Inconnu',
    'no_data': 'Aucune donnée'
  }
};

function detectLanguage(matiereName) {
  if (!matiereName) return 'ar';
  
  const matiereLower = matiereName.toLowerCase();
  
  const frenchKeywords = [
    'expression orale', 'lecture', 'production écrite', 'écriture', 
    'dictée', 'langue', 'anglais', 'français', 'english', 'french',
    'oral', 'écrit', 'rédaction'
  ];
  
  for (const keyword of frenchKeywords) {
    if (matiereLower.includes(keyword)) {
      return 'fr';
    }
  }
  
  // Vérifier les caractères arabes
  const arabicChars = /[\u0600-\u06FF]/;
  return arabicChars.test(matiereName) ? 'ar' : 'fr';
}

function getTranslation(lang, key) {
  return TRANSLATIONS[lang]?.[key] || TRANSLATIONS['ar'][key] || key;
}

exports.generateHTMLReport = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== 'POST') {
        return res.status(405).send('Method Not Allowed');
      }

      const data = req.body;
      console.log('Données reçues:', data);

      // Détecter la langue
      const matiereName = data.matiereName || '';
      const lang = detectLanguage(matiereName);
      
      const t = (key) => getTranslation(lang, key);

      // Date actuelle
      const currentDate = new Date().toISOString().replace('T', ' ').substring(0, 19);

      // Génération des en-têtes de colonnes
      const baremesHeaders = (data.baremes || [])
        .map(bareme => `<th>${bareme.value}</th>`)
        .join('');
      
      // Génération des lignes d'élèves
      let studentsRows = '';
      const students = data.students || [];
      
      students.forEach(student => {
        const cells = (data.baremes || [])
          .map(bareme => {
            const mark = student.baremes?.[bareme.id] || '( - - - )';
            return `<td>${mark}</td>`;
          })
          .join('');
        studentsRows += `<tr><td>${student.name || t('unknown')}</td>${cells}</tr>`;
      });

      // Génération des statistiques
      const sumCriteria = data.sumCriteriaMaxPerBareme || {};
      const sumCells = (data.baremes || [])
        .map(bareme => `<td>${sumCriteria[bareme.id] || 0}</td>`)
        .join('');
      
      // Calcul des pourcentages
      const totalStudents = data.totalStudents || 0;
      const percentageCells = (data.baremes || [])
        .map(bareme => {
          const achievedCount = sumCriteria[bareme.id] || 0;
          const percentage = totalStudents > 0 ? (achievedCount / totalStudents * 100) : 0;
          return `<td>${percentage.toFixed(2)}%</td>`;
        })
        .join('');

      // Déterminer la direction du texte
      const textDirection = lang === 'fr' ? 'ltr' : 'rtl';
      const textAlign = lang === 'fr' ? 'left' : 'right';

      // Construction du HTML
      const htmlContent = `
<!DOCTYPE html>
<html lang="${lang}" dir="${textDirection}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${t('title')}</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f8f9fa;
            color: #333;
        }
        
        .container {
            max-width: 100%;
            margin: 0 auto;
            padding: 15px;
        }
        
        .header {
            background: white;
            padding: 15px;
            margin-bottom: 15px;
            border: 1px solid #075260;
            border-radius: 5px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .header-info {
            flex: 1;
            min-width: 200px;
            text-align: ${textAlign};
        }
        
        .header-title {
            flex: 2;
            text-align: center;
        }
        
        .header-logo {
            flex: 1;
            min-width: 150px;
            text-align: ${lang === 'fr' ? 'right' : 'left'};
        }
        
        .header-text {
            margin: 3px 0;
            font-size: 14px;
        }
        
        .logo {
            height: 60px;
            max-width: 100%;
            object-fit: contain;
        }
        
        .table-container {
            width: 100%;
            overflow-x: auto;
            margin: 15px 0;
            border-radius: 5px;
            box-shadow: 0 0 5px rgba(0,0,0,0.1);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }
        
        th, td {
            border: 1px solid #075260;
            padding: 6px 8px;
            text-align: center;
        }
        
        th {
            background-color: #075260;
            color: white;
            font-weight: bold;
        }
        
        .print-btn {
            position: fixed;
            top: 10px;
            left: 10px;
            padding: 8px 15px;
            background-color: #075260;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            z-index: 1000;
            font-size: 14px;
        }
        
        @media print {
            @page {
                size: A4;
                margin: 10mm;
            }
            
            body {
                padding: 0;
                background-color: white;
                font-size: 11pt;
            }
            
            .print-btn {
                display: none;
            }
            
            table {
                page-break-inside: auto;
            }
            
            tr {
                page-break-inside: avoid;
            }
        }
    </style>
</head>
<body>
    <button class="print-btn" onclick="window.print()">${t('print_button')}</button>

    <div class="container">
        <div class="header">
            <div class="header-info">
                <p class="header-text"><strong>${t('professor')}:</strong> ${data.profName || t('unknown')}</p>
                <p class="header-text"><strong>${t('subject')}:</strong> ${data.matiereName || t('unknown')}</p>
                <p class="header-text"><strong>${t('class')}:</strong> ${data.className || t('unknown')}</p>
            </div>
            
            <div class="header-title">
                <h2 style="margin:0;color:#075260;">${t('main_title')}</h2>
            </div>
            
            <div class="header-logo">
                <p class="header-text"><strong>${t('school')}:</strong> ${data.schoolName || t('unknown')}</p>
            </div>
        </div>
        
        <div class="table-container">
            <table dir="${textDirection}">
                <thead>
                    <tr>
                        <th>${t('student_name')}</th>
                        ${baremesHeaders}
                    </tr>
                </thead>
                <tbody>
                    ${studentsRows || `<tr><td colspan="${(data.baremes || []).length + 1}" style="text-align:center;">${t('no_data')}</td></tr>`}
                    
                    <tr style="background-color: #e9ecef;">
                        <td><strong>${t('achieved_students')}</strong></td>
                        ${sumCells}
                    </tr>
                    
                    <tr style="background-color: #e9ecef;">
                        <td><strong>${t('percentage')}</strong></td>
                        ${percentageCells}
                    </tr>
                </tbody>
            </table>
        </div>
        
        <div style="text-align: center; margin-top: 15px; font-size: 12px;">
            <p>${t('generated_by')} - ${currentDate}</p>
        </div>
    </div>
</body>
</html>`;

      res.set('Content-Type', 'text/html; charset=utf-8');
      res.send(htmlContent);

    } catch (error) {
      console.error('Erreur:', error);
      res.status(500).send(`Erreur lors de la génération du rapport: ${error.message}`);
    }
  });
});