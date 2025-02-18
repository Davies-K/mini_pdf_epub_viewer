import 'package:flutter/material.dart';
import 'package:mini_pdf_epub_viewer/mini_pdf_epub_viewer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DocumentViewer(
        /// Add this line to change the theme
        themeMode: ThemeMode.dark,
        thumbnailWidth: 150,
        source: DocumentSource.asset('assets/epub/minimal.epub'),
        type: DocumentType.epub,
      ),

      /// For file
      // home: DocumentViewer(
      //   source: DocumentSource.file('/path/to/file.pdf'),
      //   type: DocumentType.pdf,
      // )
      /// For network
      /// home: DocumentViewer(
      ///  source: DocumentSource.network(
      ///   'https://pdfobject.com/pdf/sample.pdf',
      ///  headers: {}, // Optional
      /// ),
    );
  }
}
