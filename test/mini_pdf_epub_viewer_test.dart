import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pdf_epub_viewer/mini_pdf_epub_viewer.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('DocumentViewer displays PDF document',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentViewer(
            source: DocumentSource.asset('assets/pdf/sample.pdf'),
            type: DocumentType.pdf,
          ),
        ),
      ),
    );

    expect(find.byType(DocumentViewer), findsOneWidget);
  });

  testWidgets('DocumentViewer displays Network PDF document',
      (WidgetTester tester) async {
    const documentSource =
        DocumentSource.network('https://pdfobject.com/pdf/sample.pdf');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentViewer(
            source: documentSource,
            type: DocumentType.pdf,
          ),
        ),
      ),
    );

    expect(find.byType(DocumentViewer), findsOneWidget);
  });
}
