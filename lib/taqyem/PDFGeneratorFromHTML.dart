import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PDFGeneratorFromHTML {
  static Future<File> generatePDFFromHTML({
    required String htmlContent,
    required String fileName,
  }) async {
    try {
      print('Début de la génération PDF...');
      
      // Créer un dossier temporaire
      final directory = await getTemporaryDirectory();
      final targetPath = directory.path;
      
      print('Chemin cible: $targetPath');
      
      // Générer le PDF
      final generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(
        htmlContent,
        targetPath,
        fileName,
      );
      
      print('PDF généré avec succès: ${generatedPdfFile.path}');
      
      return generatedPdfFile;
    } catch (e) {
      print('Erreur lors de la génération du PDF: $e');
      rethrow;
    }
  }

  static Future<void> saveAndOpenPDF(File pdfFile) async {
    try {
      // Pour mobile/desktop
      await OpenFile.open(pdfFile.path);
      
      print('PDF ouvert avec succès');
    } catch (e) {
      print('Erreur lors de l\'ouverture du PDF: $e');
      rethrow;
    }
  }

  static Future<void> sharePDF(File pdfFile) async {
    try {
      // Vous pouvez utiliser share_plus pour partager le fichier
      // await Share.shareXFiles([XFile(pdfFile.path)]);
      
      print('PDF prêt pour partage: ${pdfFile.path}');
    } catch (e) {
      print('Erreur lors du partage du PDF: $e');
    }
  }
}