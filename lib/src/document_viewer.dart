import 'package:flutter/material.dart';

import 'epub/epub_document_view.dart';
import 'models/document_source.dart';
import 'models/document_type.dart';
import 'pdf/pdf_document_view.dart';
import 'viewer_style.dart';

/// A widget that displays a document viewer for PDF and EPUB files.
///
/// PDFs scroll continuously with pinch and double-tap zoom and an optional
/// thumbnail sidebar. EPUBs are shown as reflowable text one section at a
/// time, with the table of contents in the sidebar.
///
/// The widget provides various customization options such as thumbnail
/// width, selected thumbnail color, page transition duration, and curve.
///
/// Example usage:
/// ```dart
/// DocumentViewer(
///   source: DocumentSource.asset('assets/sample.pdf'),
///   type: DocumentType.pdf,
///   thumbnailWidth: 150,
///   showThumbnails: true,
///   selectedThumbnailColor: Colors.red,
///   pageTransitionDuration: Duration(milliseconds: 500),
///   pageTransitionCurve: Curves.easeIn,
///   themeMode: ThemeMode.dark,
/// )
/// ```
///
/// Params:
/// - [source]: The source of the document to be displayed. This is a required parameter.
/// - [type]: The type of the document (PDF or EPUB). This is a required parameter.
/// - [thumbnailWidth]: The width of the sidebar (PDF thumbnails or EPUB table of contents). Defaults to 200.
/// - [showThumbnails]: Whether to show the sidebar. Defaults to true.
/// - [selectedThumbnailColor]: The accent colour for the current page and controls. Defaults to iOS system blue.
/// - [pageTransitionDuration]: The duration of page and section transitions. Defaults to 300 milliseconds.
/// - [pageTransitionCurve]: The curve of EPUB section transitions and sidebar scrolling. Defaults to Curves.easeInOut.
/// - [themeMode]: The theme mode of the document viewer (light, dark, or system default). If not provided, it defaults to the system theme.
class DocumentViewer extends StatelessWidget {
  final DocumentSource source;
  final DocumentType type;
  final double? thumbnailWidth;
  final bool showThumbnails;
  final Color? selectedThumbnailColor;
  final Duration pageTransitionDuration;
  final Curve pageTransitionCurve;
  final ThemeMode? themeMode;

  const DocumentViewer({
    super.key,
    required this.source,
    required this.type,
    this.thumbnailWidth = 200,
    this.showThumbnails = true,
    this.selectedThumbnailColor,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.easeInOut,
    this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final style = ViewerStyle.of(
      context,
      themeMode: themeMode,
      accentColor: selectedThumbnailColor,
    );
    // Keyed on the document so a new source or type reloads from scratch.
    final key = ValueKey((source, type));
    return switch (type) {
      DocumentType.pdf => PdfDocumentView(
          key: key,
          source: source,
          style: style,
          thumbnailWidth: thumbnailWidth ?? 200,
          showThumbnails: showThumbnails,
          pageTransitionDuration: pageTransitionDuration,
          pageTransitionCurve: pageTransitionCurve,
        ),
      DocumentType.epub => EpubDocumentView(
          key: key,
          source: source,
          style: style,
          sidebarWidth: thumbnailWidth ?? 200,
          showTableOfContents: showThumbnails,
          pageTransitionDuration: pageTransitionDuration,
          pageTransitionCurve: pageTransitionCurve,
        ),
    };
  }
}
