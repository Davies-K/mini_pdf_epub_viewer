import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'models/document_source.dart';
import 'models/document_type.dart';

class DocumentViewer extends StatefulWidget {
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
    this.selectedThumbnailColor = Colors.blue,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.easeInOut,
    this.themeMode,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  PdfController? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _error;
  final Map<int, Future<PdfPageImage?>> _thumbnails = {};
  // TODO(davies-k): Implement editing functionality
  // double _rotation = 0.0;
  // bool _isEditing = false;
  final _transformationController = TransformationController();
  double _scale = 1.0;

  bool get _isDark {
    if (widget.themeMode != null) {
      return widget.themeMode == ThemeMode.dark;
    }
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color get _backgroundColor => _isDark ? Colors.grey[900]! : Colors.white;
  Color get _surfaceColor => _isDark ? Colors.grey[800]! : Colors.grey[200]!;
  Color get _borderColor => _isDark ? Colors.grey[700]! : Colors.grey[300]!;
  Color get _textColor => _isDark ? Colors.grey[100]! : Colors.grey[900]!;
  Color get _secondaryTextColor =>
      _isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get _selectedColor =>
      widget.selectedThumbnailColor ??
      (_isDark ? Colors.blue[300]! : Colors.blue);

  @override
  void initState() {
    super.initState();
    _initializeDocument();
  }

  Future<File> _getFileFromSource() async {
    try {
      final String filename = widget.source.path.split('/').last;
      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String localPath = '$dir/$filename';
      final File file = File(localPath);

      switch (widget.source.sourceType) {
        case DocumentSourceType.asset:
          final ByteData data = await rootBundle.load(widget.source.path);
          await file.writeAsBytes(data.buffer.asUint8List());
          break;

        case DocumentSourceType.file:
          return File(widget.source.path);

        case DocumentSourceType.network:
          final response = await http.get(
            Uri.parse(widget.source.path),
            headers: widget.source.headers,
          );
          if (response.statusCode != 200) {
            throw Exception('Failed to download file: ${response.statusCode}');
          }
          await file.writeAsBytes(response.bodyBytes);
          break;
      }

      return file;
    } catch (e) {
      throw Exception('Failed to load document: $e');
    }
  }

  Future<void> _initializeDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = await _getFileFromSource();

      switch (widget.type) {
        case DocumentType.pdf:
          await _initializePdf(file);
          break;
        case DocumentType.epub:
          // TODO: Implement epub support
          throw UnimplementedError('EPUB support coming soon');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      debugPrint('Error loading document: $e');
    }
  }

  Future<void> _initializePdf(File file) async {
    final document = await PdfDocument.openFile(file.path);
    _totalPages = document.pagesCount;

    _pdfController = PdfController(
      document: PdfDocument.openFile(file.path),
    );

    if (widget.showThumbnails) {
      for (int i = 1; i <= _totalPages; i++) {
        _thumbnails[i] = _generateThumbnail(i, file.path);
      }
    }
  }

  Future<PdfPageImage?> _generateThumbnail(
      int pageNumber, String filePath) async {
    try {
      final document = await PdfDocument.openFile(filePath);
      final page = await document.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width / 4,
        height: page.height / 4,
      );
      await page.close();
      return pageImage;
    } catch (e) {
      debugPrint('Error generating thumbnail for page $pageNumber: $e');
      return null;
    }
  }

  Widget _buildHeader() {
    final fileName = widget.source.path.split('/').last;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: _borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: _textColor,
                  ),
                ),
                Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: _textColor),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: _backgroundColor,
                        title: Text('General Info',
                            style: TextStyle(color: _textColor)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filename: $fileName',
                                style: TextStyle(color: _textColor)),
                            Text('Total Pages: $_totalPages',
                                style: TextStyle(color: _textColor)),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close',
                                style: TextStyle(color: _selectedColor)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.zoom_out, color: _textColor),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale - 0.25).clamp(0.5, 3.0);
                      final matrix = Matrix4.identity()..scale(_scale, _scale);
                      _transformationController.value = matrix;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.zoom_in, color: _textColor),
                  onPressed: () {
                    setState(() {
                      _scale = (_scale + 0.25).clamp(0.5, 3.0);
                      final matrix = Matrix4.identity()..scale(_scale, _scale);
                      _transformationController.value = matrix;
                    });
                  },
                ),

                // Edit button
                // IconButton(
                //   icon: Icon(
                //     _isEditing ? Icons.edit_off : Icons.edit,
                //     color: _isEditing ? Colors.blue : null,
                //   ),
                //   onPressed: () {
                //     setState(() {
                //       _isEditing = !_isEditing;
                //       // Implement PDF editing functionality here
                //     });
                //   },
                // ),
                // Rotate button
                // IconButton(
                //   icon: const Icon(Icons.rotate_right),
                //   onPressed: () {

                //     // setState(() {
                //     //   _rotation = (_rotation + 90) % 360;
                //     //   final matrix = Matrix4.identity()
                //     //     ..scale(_scale, _scale)
                //     //     ..rotateZ(_rotation * 3.14159 / 180);
                //     //   _transformationController.value = matrix;
                //     // });
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: _isDark ? Colors.red[300] : Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading PDF',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _secondaryTextColor,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeDocument(),
              child: Text('Try Again',
                  style: TextStyle(
                      color: _isDark ? Colors.grey[900] : Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _selectedColor),
          const SizedBox(height: 16),
          Text('Loading PDF...', style: TextStyle(color: _textColor)),
        ],
      ),
    );
  }

  Widget _buildThumbnail(int pageNumber) {
    return FutureBuilder<PdfPageImage?>(
      future: _thumbnails[pageNumber],
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Icon(Icons.error));
        }

        return Image.memory(
          snapshot.data!.bytes,
          fit: BoxFit.contain,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _error != null
                      ? _buildErrorWidget()
                      : _buildDocumentViewer(),
            ),
          ],
        ),
        bottomNavigationBar: _buildNavigationBar(),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    if (widget.type == DocumentType.epub) {
      return const Center(child: Text('EPUB support coming soon'));
    }

    return Row(
      children: [
        if (widget.showThumbnails) _buildThumbnailSidebar(),
        Expanded(child: _buildMainViewer()),
      ],
    );
  }

  Widget _buildThumbnailSidebar() {
    return Container(
      width: widget.thumbnailWidth,
      color: _surfaceColor,
      child: Column(
        children: [
          const SizedBox(
            height: 88,
            width: 200,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _totalPages,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pdfController?.animateToPage(
                      index + 1,
                      duration: widget.pageTransitionDuration,
                      curve: widget.pageTransitionCurve,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          height: 150,
                          decoration: BoxDecoration(
                            border: _currentPage == index + 1
                                ? Border.all(color: _selectedColor, width: 2)
                                : null,
                            color: _isDark ? Colors.grey[850] : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _buildThumbnail(index + 1),
                        ),
                        Text(
                          ((index + 1).toString()),
                          style: TextStyle(color: _textColor),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainViewer() {
    if (_pdfController == null) {
      return const Center(child: Text('Document viewer not initialized'));
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 3.0,
            child: PdfView(
              controller: _pdfController!,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              builders: PdfViewBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) => _buildLoadingWidget(),
                pageLoaderBuilder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorBuilder: (_, error) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildNavigationBar() {
    if (_error != null || _isLoading) return null;

    return Container(
      padding: const EdgeInsets.all(8),
      color: _surfaceColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.navigate_before, color: _textColor),
            onPressed: _currentPage > 1
                ? () => _pdfController?.previousPage(
                    duration: widget.pageTransitionDuration,
                    curve: widget.pageTransitionCurve)
                : null,
          ),
          Text('Page $_currentPage of $_totalPages',
              style: TextStyle(color: _textColor)),
          IconButton(
            icon: Icon(Icons.navigate_next, color: _textColor),
            onPressed: _currentPage < _totalPages
                ? () => _pdfController?.nextPage(
                    duration: widget.pageTransitionDuration,
                    curve: widget.pageTransitionCurve)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }
}
