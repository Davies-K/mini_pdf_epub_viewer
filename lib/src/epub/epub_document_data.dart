import 'package:epub_plus/epub_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;

/// One HTML file from the EPUB spine, in reading order.
@immutable
class EpubSection {
  const EpubSection({required this.fileName, required this.bodyHtml});

  /// Path of the file inside the EPUB content directory, used to resolve
  /// relative image and link URLs.
  final String fileName;

  /// The `<body>` contents with scripts and publisher styles removed.
  final String bodyHtml;
}

/// A flattened table of contents entry.
@immutable
class EpubTocEntry {
  const EpubTocEntry({
    required this.title,
    required this.sectionIndex,
    required this.depth,
  });

  final String title;
  final int sectionIndex;
  final int depth;
}

/// Everything the EPUB view needs, extracted from the archive up front so
/// parsing can run off the UI isolate.
@immutable
class EpubDocumentData {
  const EpubDocumentData({
    required this.title,
    required this.author,
    required this.sections,
    required this.tableOfContents,
    required this.images,
  });

  final String title;
  final String author;
  final List<EpubSection> sections;
  final List<EpubTocEntry> tableOfContents;

  /// Image bytes keyed by their path inside the content directory.
  final Map<String, Uint8List> images;

  /// Returns the index of the section stored at [fileName], or -1.
  int indexOfSection(String fileName) =>
      sections.indexWhere((section) => section.fileName == fileName);

  /// Resolves [url] as written in [section]'s HTML to a path inside the
  /// content directory, dropping any `#fragment`.
  static String resolvePath(EpubSection section, String url) {
    final resolved = Uri.parse(section.fileName).resolve(url);
    return Uri.decodeFull(resolved.path);
  }
}

/// Parses [bytes] into [EpubDocumentData]. Top-level so it can be passed to
/// [compute].
Future<EpubDocumentData> parseEpub(Uint8List bytes) async {
  final bookRef = await EpubReader.openBook(bytes);
  final content = await EpubReader.readContent(bookRef.content!);
  final package = bookRef.schema?.package;

  final hrefById = {
    for (final item in package?.manifest?.items ?? const <EpubManifestItem>[])
      if (item.id != null && item.href != null)
        item.id!: Uri.decodeFull(item.href!),
  };
  final spineFiles = [
    for (final item in package?.spine?.items ?? const <EpubSpineItemRef>[])
      if (hrefById[item.idRef] case final href?) href,
  ];
  // Fall back to manifest order for books without a usable spine.
  final fileNames = spineFiles.where(content.html.containsKey).isNotEmpty
      ? spineFiles.where(content.html.containsKey)
      : content.html.keys;

  final sections = [
    for (final fileName in fileNames)
      EpubSection(
        fileName: fileName,
        bodyHtml: _extractBody(content.html[fileName]?.content ?? ''),
      ),
  ];

  final tableOfContents = <EpubTocEntry>[];
  void addChapters(List<EpubChapterRef> chapters, int depth) {
    for (final chapter in chapters) {
      final index = sections
          .indexWhere((section) => section.fileName == chapter.contentFileName);
      final title = chapter.title?.trim() ?? '';
      if (index != -1 && title.isNotEmpty) {
        tableOfContents.add(
          EpubTocEntry(title: title, sectionIndex: index, depth: depth),
        );
      }
      addChapters(chapter.subChapters, depth + 1);
    }
  }

  addChapters(bookRef.getChapters(), 0);

  return EpubDocumentData(
    title: bookRef.title ?? '',
    author: bookRef.author ?? '',
    sections: sections,
    tableOfContents: tableOfContents,
    images: {
      for (final entry in content.images.entries)
        if (entry.value.content != null)
          entry.key: Uint8List.fromList(entry.value.content!),
    },
  );
}

String _extractBody(String xhtml) {
  final body = html_parser.parse(xhtml).body;
  if (body == null) return '';
  for (final element in body.querySelectorAll('script, style, link')) {
    element.remove();
  }
  return body.innerHtml;
}
