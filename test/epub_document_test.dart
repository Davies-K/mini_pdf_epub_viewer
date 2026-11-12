import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_pdf_epub_viewer/mini_pdf_epub_viewer.dart';
import 'package:mini_pdf_epub_viewer/src/epub/epub_document_data.dart';

const _fixturePath = 'test/fixtures/sample.epub';

void main() {
  group('parseEpub', () {
    late EpubDocumentData book;

    setUpAll(() async {
      book = await parseEpub(await File(_fixturePath).readAsBytes());
    });

    test('reads metadata', () {
      expect(book.title, 'Sample Book');
      expect(book.author, 'Mini Viewer');
    });

    test('orders sections by the spine', () {
      expect(book.sections.map((s) => s.fileName), [
        'Text/cover.xhtml',
        'Text/chapter1.xhtml',
        'Text/chapter1b.xhtml',
        'Text/chapter2.xhtml',
        'Text/chapter3.xhtml',
      ]);
    });

    test('keeps only the body and drops publisher styles', () {
      final html = book.sections[1].bodyHtml;
      expect(html, contains('Chapter 1: Beginnings'));
      expect(html, isNot(contains('<style')));
      expect(html, isNot(contains('<title')));
    });

    test('flattens the nested table of contents', () {
      expect(
        book.tableOfContents.map((e) => (e.title, e.sectionIndex, e.depth)),
        [
          ('Chapter 1: Beginnings', 1, 0),
          ('An Interlude', 2, 1),
          ('Chapter 2: The Middle', 3, 0),
          ('Chapter 3: Endings', 4, 0),
        ],
      );
    });

    test('resolves relative image paths against the section', () {
      final path = EpubDocumentData.resolvePath(
          book.sections[1], '../Images/figure.png');
      expect(path, 'Images/figure.png');
      expect(book.images[path], isNotEmpty);
      expect(book.images.keys, contains('Images/cover.png'));
    });
  });

  testWidgets('EPUB viewer navigates by table of contents and arrows',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: DocumentViewer(
          source: DocumentSource.file(_fixturePath),
          type: DocumentType.epub,
        ),
      ),
    );
    expect(find.text('Loading EPUB...'), findsOneWidget);

    await _pumpUntilLoaded(tester);

    expect(find.text('Sample Book'), findsOneWidget);
    expect(find.text('1 of 5'), findsWidgets);

    await tester.tap(find.text('Chapter 2: The Middle'));
    await _pumpUntilLoaded(tester);
    expect(find.text('4 of 5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.navigate_before));
    await _pumpUntilLoaded(tester);
    expect(find.text('3 of 5'), findsOneWidget);
    // The interlude has its own entry, shown as the header subtitle.
    expect(find.text('An Interlude'), findsWidgets);
  });

  testWidgets('EPUB viewer shows an error for a missing file', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DocumentViewer(
          source: DocumentSource.file('test/fixtures/missing.epub'),
          type: DocumentType.epub,
        ),
      ),
    );
    await _pumpUntilLoaded(tester);
    expect(find.text('Error loading EPUB'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });

  group('DocumentSource.displayName', () {
    test('uses the last path segment', () {
      expect(const DocumentSource.file('/a/b/c.pdf').displayName, 'c.pdf');
      expect(const DocumentSource.asset('assets/x.epub').displayName, 'x.epub');
    });

    test('ignores URL queries', () {
      expect(
        const DocumentSource.network('https://x.com/doc%20one.pdf?token=1')
            .displayName,
        'doc one.pdf',
      );
    });
  });
}

/// File reads, compute() and the HTML renderer's async build need real time
/// to pass, which pumpAndSettle alone does not provide.
Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}
