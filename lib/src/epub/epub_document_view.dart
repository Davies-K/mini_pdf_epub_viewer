import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/dom.dart' as dom;

import '../loading/document_bytes.dart';
import '../models/document_source.dart';
import '../viewer_chrome.dart';
import '../viewer_style.dart';
import 'epub_document_data.dart';

/// Shows an EPUB one section (spine file) at a time as reflowable text, with
/// the table of contents in the sidebar.
class EpubDocumentView extends StatefulWidget {
  const EpubDocumentView({
    super.key,
    required this.source,
    required this.style,
    required this.sidebarWidth,
    required this.showTableOfContents,
    required this.pageTransitionDuration,
    required this.pageTransitionCurve,
  });

  final DocumentSource source;
  final ViewerStyle style;
  final double sidebarWidth;
  final bool showTableOfContents;
  final Duration pageTransitionDuration;
  final Curve pageTransitionCurve;

  @override
  State<EpubDocumentView> createState() => _EpubDocumentViewState();
}

class _EpubDocumentViewState extends State<EpubDocumentView> {
  static const double _baseFontSize = 18;
  static const double _minTextScale = 0.7;
  static const double _maxTextScale = 2.0;
  static const double _maxLineWidth = 680;

  EpubDocumentData? _book;
  Object? _error;
  int _sectionIndex = 0;
  double _textScale = 1.0;

  ViewerStyle get _style => widget.style;
  int get _sectionCount => _book?.sections.length ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _book = null;
      _error = null;
    });
    try {
      final bytes = await loadDocumentBytes(widget.source);
      final book = await compute(parseEpub, bytes);
      if (book.sections.isEmpty) {
        throw const FormatException('The EPUB has no readable sections.');
      }
      if (!mounted) return;
      setState(() {
        _book = book;
        _sectionIndex = 0;
      });
    } catch (e) {
      debugPrint('Error loading document: $e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _goToSection(int index) {
    if (index < 0 || index >= _sectionCount || index == _sectionIndex) return;
    // Each section gets a fresh scroll view, so it opens at the top.
    setState(() => _sectionIndex = index);
  }

  void _changeTextScale(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(_minTextScale, _maxTextScale);
    });
  }

  /// The deepest table of contents entry that starts at or before the
  /// current section, so sections without their own entry keep the title of
  /// the chapter they belong to.
  EpubTocEntry? get _currentTocEntry {
    EpubTocEntry? current;
    for (final entry in _book?.tableOfContents ?? const <EpubTocEntry>[]) {
      if (entry.sectionIndex > _sectionIndex) break;
      current = entry;
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final book = _book;
    final isReady = book != null;
    final positionLabel = '${_sectionIndex + 1} of $_sectionCount';
    return ViewerScaffold(
      style: _style,
      title: isReady && book.title.isNotEmpty
          ? book.title
          : widget.source.displayName,
      subtitle: isReady ? _currentTocEntry?.title ?? positionLabel : null,
      actions: [
        ViewerIconButton(
          style: _style,
          icon: Icons.info_outline,
          tooltip: 'Info',
          onPressed: isReady
              ? () => showDocumentInfo(context, style: _style, details: {
                    'Filename': widget.source.displayName,
                    if (book.title.isNotEmpty) 'Title': book.title,
                    if (book.author.isNotEmpty) 'Author': book.author,
                    'Sections': '$_sectionCount',
                  })
              : null,
        ),
        ViewerIconButton(
          style: _style,
          icon: Icons.text_decrease,
          tooltip: 'Smaller text',
          onPressed: isReady && _textScale > _minTextScale
              ? () => _changeTextScale(-0.1)
              : null,
        ),
        ViewerIconButton(
          style: _style,
          icon: Icons.text_increase,
          tooltip: 'Larger text',
          onPressed: isReady && _textScale < _maxTextScale
              ? () => _changeTextScale(0.1)
              : null,
        ),
      ],
      sidebar: widget.showTableOfContents && isReady
          ? _buildTableOfContents(book)
          : null,
      sidebarWidth: widget.sidebarWidth,
      navigationLabel: isReady ? positionLabel : null,
      onPrevious:
          _sectionIndex > 0 ? () => _goToSection(_sectionIndex - 1) : null,
      onNext: _sectionIndex < _sectionCount - 1
          ? () => _goToSection(_sectionIndex + 1)
          : null,
      body: ColoredBox(
        color: _style.pageColor,
        child: _error != null
            ? ViewerErrorView(
                style: _style,
                title: 'Error loading EPUB',
                error: _error!,
                onRetry: _load,
              )
            : isReady
                ? _buildSection(book)
                : ViewerLoadingView(style: _style, label: 'Loading EPUB...'),
      ),
    );
  }

  Widget _buildSection(EpubDocumentData book) {
    final section = book.sections[_sectionIndex];
    return AnimatedSwitcher(
      duration: widget.pageTransitionDuration,
      switchInCurve: widget.pageTransitionCurve,
      switchOutCurve: widget.pageTransitionCurve,
      child: LayoutBuilder(
        key: ValueKey(_sectionIndex),
        builder: (context, constraints) {
          final horizontalPadding =
              math.max(24.0, (constraints.maxWidth - _maxLineWidth) / 2);
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  32,
                  horizontalPadding,
                  16,
                ),
                sliver: HtmlWidget(
                  section.bodyHtml,
                  renderMode: RenderMode.sliverList,
                  textStyle: TextStyle(
                    fontSize: _baseFontSize * _textScale,
                    height: 1.5,
                    color: _style.textColor,
                  ),
                  customStylesBuilder: (element) => element.localName == 'a'
                      ? {'color': _cssColor(_style.accentColor)}
                      : null,
                  customWidgetBuilder: (element) =>
                      _buildEmbeddedImage(book, section, element),
                  onTapUrl: (url) => _handleLinkTap(book, section, url),
                ),
              ),
              SliverToBoxAdapter(child: _buildSectionFooter()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionFooter() {
    final hasNext = _sectionIndex < _sectionCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Center(
        child: hasNext
            ? TextButton.icon(
                onPressed: () => _goToSection(_sectionIndex + 1),
                icon: const Icon(Icons.arrow_downward),
                label: const Text('Next section'),
                style: TextButton.styleFrom(
                  foregroundColor: _style.accentColor,
                ),
              )
            : Text(
                'End of book',
                style: TextStyle(color: _style.secondaryTextColor),
              ),
      ),
    );
  }

  /// Renders `<img>` and SVG-wrapped `<image>` elements from the EPUB's own
  /// files, which the HTML renderer cannot resolve by itself.
  Widget? _buildEmbeddedImage(
    EpubDocumentData book,
    EpubSection section,
    dom.Element element,
  ) {
    final imageElement = switch (element.localName) {
      'img' || 'image' => element,
      'svg' => element.querySelector('image'),
      _ => null,
    };
    if (imageElement == null) return null;

    String? src;
    imageElement.attributes.forEach((name, value) {
      final attribute = name.toString();
      if (attribute == 'src' || attribute.endsWith('href')) src ??= value;
    });
    if (src == null) return null;

    final bytes = book.images[EpubDocumentData.resolvePath(section, src!)];
    if (bytes == null) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Image.memory(bytes, fit: BoxFit.contain),
    );
  }

  /// Follows links between sections of the book; external links are left to
  /// the HTML renderer.
  bool _handleLinkTap(
    EpubDocumentData book,
    EpubSection section,
    String url,
  ) {
    if (Uri.tryParse(url)?.hasScheme ?? true) return false;
    final index = book.indexOfSection(
      EpubDocumentData.resolvePath(section, url),
    );
    if (index == -1) return false;
    _goToSection(index);
    return true;
  }

  Widget _buildTableOfContents(EpubDocumentData book) {
    final currentEntry = _currentTocEntry;
    final entries = book.tableOfContents.isNotEmpty
        ? book.tableOfContents
        : [
            for (var i = 0; i < book.sections.length; i++)
              EpubTocEntry(
                  title: 'Section ${i + 1}', sectionIndex: i, depth: 0),
          ];
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isSelected = currentEntry == null
            ? entry.sectionIndex == _sectionIndex
            : identical(entry, currentEntry);
        return InkWell(
          onTap: () => _goToSection(entry.sectionIndex),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12.0 + entry.depth * 12,
              10,
              12,
              10,
            ),
            color:
                isSelected ? _style.accentColor.withValues(alpha: 0.12) : null,
            child: Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? _style.accentColor : _style.textColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: entry.depth == 0 ? 14 : 13,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _cssColor(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}
