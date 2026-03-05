// import 'dart:async';
// import 'dart:convert';
// import 'dart:html' as html;
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class WebDownloadService {
//   // Télécharger HTML sur web
//   static Future<void> downloadHtml(String htmlContent, String baseName) async {
//     try {
//       print('🔄 Début téléchargement HTML sur web');
//       print('📏 Longueur HTML: ${htmlContent.length} caractères');
      
//       final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.html';
      
//       // Encoder en UTF-8
//       final bytes = Uint8List.fromList(utf8.encode(htmlContent));
      
//       // Créer un Blob
//       final blob = html.Blob([bytes], 'text/html; charset=utf-8');
//       final url = html.Url.createObjectUrlFromBlob(blob);
      
//       print('✅ Blob créé, URL: $url');
      
//       // Créer et configurer l'élément anchor
//       final anchor = html.AnchorElement()
//         ..href = url
//         ..download = fileName
//         ..style.display = 'none';
      
//       // Ajouter au DOM
//       html.document.body?.append(anchor);
      
//       // Simuler le clic
//       anchor.click();
      
//       // Attendre un peu puis nettoyer
//       await Future.delayed(const Duration(milliseconds: 100));
      
//       // Retirer l'élément
//       anchor.remove();
      
//       // Libérer l'URL
//       html.Url.revokeObjectUrl(url);
      
//       print('✅ Téléchargement HTML initié: $fileName');
//     } catch (e, stackTrace) {
//       print('❌ Erreur téléchargement HTML: $e');
//       print('Stack trace: $stackTrace');
      
//       // Fallback: ouvrir dans un nouvel onglet
//       await openInNewTab(htmlContent);
//     }
//   }
  
//   // Télécharger PDF sur web
//   static Future<void> downloadPdf(Uint8List pdfBytes, String baseName) async {
//     try {
//       print('🔄 Début téléchargement PDF sur web');
//       print('📏 Taille PDF: ${pdfBytes.length} bytes');
      
//       final fileName = '${baseName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
//       // Créer un Blob PDF
//       final blob = html.Blob([pdfBytes], 'application/pdf');
//       final url = html.Url.createObjectUrlFromBlob(blob);
      
//       print('✅ Blob PDF créé, URL: $url');
      
//       // Créer et configurer l'élément anchor
//       final anchor = html.AnchorElement()
//         ..href = url
//         ..download = fileName
//         ..style.display = 'none';
      
//       // Ajouter au DOM
//       html.document.body?.append(anchor);
      
//       // Simuler le clic
//       anchor.click();
      
//       // Attendre un peu puis nettoyer
//       await Future.delayed(const Duration(milliseconds: 100));
      
//       // Retirer l'élément
//       anchor.remove();
      
//       // Libérer l'URL
//       html.Url.revokeObjectUrl(url);
      
//       print('✅ Téléchargement PDF initié: $fileName');
//     } catch (e, stackTrace) {
//       print('❌ Erreur téléchargement PDF: $e');
//       print('Stack trace: $stackTrace');
//     }
//   }
  
//   // Ouvrir dans un nouvel onglet (fallback)
//   static Future<void> openInNewTab(String htmlContent) async {
//     try {
//       print('🔄 Ouverture HTML dans nouvel onglet');
      
//       // Créer un document HTML complet
//       final fullHtml = '''
//         <!DOCTYPE html>
//         <html>
//         <head>
//           <meta charset="UTF-8">
//           <meta name="viewport" content="width=device-width, initial-scale=1.0">
//           <title>Rapport d'évaluation</title>
//           <style>
//             body { font-family: Arial, sans-serif; padding: 20px; }
//             .container { max-width: 1200px; margin: 0 auto; }
//             .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; margin: 20px 0; border-radius: 5px; }
//             button { background: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
//             button:hover { background: #0056b3; }
//           </style>
//         </head>
//         <body>
//           <div class="container">
//             <div class="warning">
//               <h3>⚠️ Mode Aperçu</h3>
//               <p>Pour sauvegarder ce rapport, utilisez "Ctrl+S" (Windows) ou "Cmd+S" (Mac).</p>
//               <button onclick="window.print()">🖨️ Imprimer</button>
//             </div>
//             <hr>
//             ${htmlContent}
//           </div>
//         </body>
//         </html>
//       ''';
      
//       // Créer un blob
//       final bytes = Uint8List.fromList(utf8.encode(fullHtml));
//       final blob = html.Blob([bytes], 'text/html; charset=utf-8');
//       final url = html.Url.createObjectUrlFromBlob(blob);
      
//       // Ouvrir dans un nouvel onglet
//       html.window.open(url, '_blank');
      
//       // Libérer l'URL après un délai
//       Future.delayed(const Duration(seconds: 2), () {
//         html.Url.revokeObjectUrl(url);
//       });
      
//       print('✅ HTML ouvert dans nouvel onglet');
//     } catch (e) {
//       print('❌ Erreur ouverture nouvel onglet: $e');
//     }
//   }
// }