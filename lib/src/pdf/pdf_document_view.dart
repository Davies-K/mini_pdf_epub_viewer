import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/document_source.dart';
import '../viewer_chrome.dart';
import '../viewer_style.dart';

/// Shows a PDF as one continuous vertical scroll of pages, like the iOS
/// reader, with sharp pinch-zoom and double-tap to zoom.
class PdfDocumentView extends StatefulWidget {
  const PdfDocumentView({
    super.key,
    required this.source,
    required this.style,
    required this.thumbnailWidth,
    required this.showThumbnails,
    required this.pageTransitionDuration,
    required this.pageTransitionCurve,
  });

  final DocumentSource source;
  final ViewerStyle style;
  final double thumbnailWidth;
  final bool showThumbnails;
  final Duration pageTransitionDuration;
  final Curve pageTransitionCurve;

  @override
  State<PdfDocumentView> createState() => _PdfDocumentViewState();
}

class _PdfDocumentViewState extends State<PdfDocumentView> {
  /// Height of one row in the thumbnail sidebar; fixed so the sidebar can
  /// scroll the current page into view without measuring.
  static const double _thumbnailExtent = 196;

  /// How far double-tap zooms in, relative to fit-to-width.
  static const double _doubleTapZoomFactor = 2.5;

  final _controller = PdfViewerController();
  final _thumbnailScrollController = ScrollController();
  late PdfDocumentRef _documentRef;
  int _loadAttempt = 0;

  PdfDocument? _document;
  int _currentPage = 1;

  ViewerStyle get _style => widget.style;
  int get _totalPages => _document?.pages.length ?? 0;

  @override
  void initState() {
    super.initState();
    _documentRef = _createDocumentRef();
  }

  /// The attempt number is part of the key so "Try Again" bypasses
  /// pdfrx's cache of the failed load.
  PdfDocumentRef _createDocumentRef() {
    final source = widget.source;
    final key = PdfDocumentRefKey(source.path, [_loadAttempt]);
    return switch (source.sourceType) {
      DocumentSourceType.asset => PdfDocumentRefAsset(source.path, key: key),
      DocumentSourceType.file => PdfDocumentRefFile(source.path, key: key),
      DocumentSourceType.network => PdfDocumentRefUri(
          Uri.parse(source.path),
          headers: source.headers,
          key: key,
        ),
    };
  }

  void _retry() {
    setState(() {
      _loadAttempt++;
      _document = null;
      _currentPage = 1;
      _documentRef = _createDocumentRef();
    });
  }

  void _goToPage(int pageNumber) {
    if (!_controller.isReady) return;
    _controller.goToPage(
      pageNumber: pageNumber,
      duration: widget.pageTransitionDuration,
    );
  }

  void _onPageChanged(int? pageNumber) {
    if (pageNumber == null || pageNumber == _currentPage) return;
    setState(() => _currentPage = pageNumber);
    _scrollThumbnailIntoView(pageNumber);
  }

  void _scrollThumbnailIntoView(int pageNumber) {
    if (!_thumbnailScrollController.hasClients) return;
    final position = _thumbnailScrollController.position;
    final top = (pageNumber - 1) * _thumbnailExtent;
    final bottom = top + _thumbnailExtent;
    if (top >= position.pixels &&
        bottom <= position.pixels + position.viewportDimension) {
      return;
    }
    final centered = top - (position.viewportDimension - _thumbnailExtent) / 2;
    _thumbnailScrollController.animateTo(
      centered.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: widget.pageTransitionDuration,
      curve: widget.pageTransitionCurve,
    );
  }

  /// Double-tap zooms in around the tap, or back out to fit-to-width when
  /// already zoomed in. For a single column of pages pdfrx's cover scale is
  /// the fit-to-width zoom.
  bool _handleTap(
    BuildContext context,
    PdfViewerController controller,
    PdfViewerGeneralTapHandlerDetails details,
  ) {
    if (details.type != PdfViewerGeneralTapType.doubleTap) return false;
    final fitZoom = controller.coverScale;
    final isZoomedIn = controller.currentZoom > fitZoom * 1.05;
    controller.zoomOnLocalPosition(
      localPosition: details.localPosition,
      newZoom: isZoomedIn ? fitZoom : fitZoom * _doubleTapZoomFactor,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _document != null;
    return ViewerScaffold(
      style: _style,
      title: widget.source.displayName,
      subtitle: isReady ? 'Page $_currentPage of $_totalPages' : null,
      actions: [
        ViewerIconButton(
          style: _style,
          icon: Icons.info_outline,
          tooltip: 'Info',
          onPressed: isReady
              ? () => showDocumentInfo(context, style: _style, details: {
                    'Filename': widget.source.displayName,
                    'Total Pages': '$_totalPages',
                  })
              : null,
        ),
        ViewerIconButton(
          style: _style,
          icon: Icons.zoom_out,
          tooltip: 'Zoom out',
          onPressed: isReady ? () => _controller.zoomDown() : null,
        ),
        ViewerIconButton(
          style: _style,
          icon: Icons.zoom_in,
          tooltip: 'Zoom in',
          onPressed: isReady ? () => _controller.zoomUp() : null,
        ),
      ],
      sidebar: widget.showThumbnails ? _buildThumbnailSidebar() : null,
      sidebarWidth: widget.thumbnailWidth,
      navigationLabel: isReady ? 'Page $_currentPage of $_totalPages' : null,
      onPrevious: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
      onNext:
          _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
      body: PdfViewer(
        _documentRef,
        controller: _controller,
        params: PdfViewerParams(
          backgroundColor: _style.canvasColor,
          margin: 12,
          sizeDelegateProvider:
              const PdfViewerSizeDelegateProviderLegacy(maxScale: 8),
          pageDropShadow: BoxShadow(
            color: Colors.black.withValues(alpha: _style.isDark ? 0.5 : 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          onViewerReady: (document, controller) {
            setState(() => _document = document);
          },
          onPageChanged: _onPageChanged,
          onGeneralTap: _handleTap,
          loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
              ViewerLoadingView(
            style: _style,
            label: 'Loading PDF...',
            progress: totalBytes == null || totalBytes == 0
                ? null
                : bytesDownloaded / totalBytes,
          ),
          errorBannerBuilder: (context, error, stackTrace, documentRef) =>
              ColoredBox(
            color: _style.backgroundColor,
            child: ViewerErrorView(
              style: _style,
              title: 'Error loading PDF',
              error: error,
              onRetry: _retry,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailSidebar() {
    return ListView.builder(
      controller: _thumbnailScrollController,
      itemCount: _totalPages,
      itemExtent: _thumbnailExtent,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final pageNumber = index + 1;
        final isSelected = pageNumber == _currentPage;
        return GestureDetector(
          onTap: () => _goToPage(pageNumber),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                height: 150,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? _style.accentColor : Colors.transparent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: PdfPageView(
                  document: _document,
                  pageNumber: pageNumber,
                  maximumDpi: 72,
                  backgroundColor: Colors.white,
                ),
              ),
              Text(
                '$pageNumber',
                style: TextStyle(
                  color: isSelected ? _style.accentColor : _style.textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _thumbnailScrollController.dispose();
    super.dispose();
  }
}
