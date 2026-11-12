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
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const SampleList(),
    );
  }
}

class SampleList extends StatelessWidget {
  const SampleList({super.key});

  static const _samples = [
    (
      'Sample PDF',
      DocumentSource.asset('assets/pdf/sample.pdf'),
      DocumentType.pdf,
    ),
    (
      'Sample EPUB',
      DocumentSource.asset('assets/epub/sample.epub'),
      DocumentType.epub,
    ),

    /// For file
    // ('Local PDF', DocumentSource.file('/path/to/file.pdf'), DocumentType.pdf),
    /// For network
    // (
    //   'Network PDF',
    //   DocumentSource.network(
    //     'https://pdfobject.com/pdf/sample.pdf',
    //     headers: {}, // Optional
    //   ),
    //   DocumentType.pdf,
    // ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini PDF & EPUB Viewer')),
      body: ListView(
        children: [
          for (final (title, source, type) in _samples)
            ListTile(
              leading: Icon(
                type == DocumentType.pdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.menu_book_outlined,
              ),
              title: Text(title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => DocumentViewer(
                    /// Add this line to change the theme
                    // themeMode: ThemeMode.dark,
                    thumbnailWidth: 150,
                    source: source,
                    type: type,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
