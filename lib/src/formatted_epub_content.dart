import 'dart:typed_data';
import 'package:epubx/epubx.dart' as epubx;
import 'package:flutter/material.dart';

class FormattedEpubContent extends StatelessWidget {
  final String htmlContent;
  final Color textColor;
  final double fontSize;
  final double lineHeight;
  final EdgeInsets padding;
  final Map<String, epubx.EpubByteContentFile>? images;
  final Size screenSize;

  const FormattedEpubContent({
    super.key,
    required this.htmlContent,
    required this.textColor,
    this.fontSize = 16,
    this.lineHeight = 1.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    this.images,
    required this.screenSize,
  });

  bool _isCoverImage(String htmlSegment) {
    // Check for common cover image indicators in class names or IDs
    return htmlSegment.toLowerCase().contains('cover') ||
        htmlSegment.toLowerCase().contains('title-page') ||
        htmlSegment.toLowerCase().contains('frontcover');
  }

  List<Widget> _parseContent(String content) {
    final List<Widget> widgets = [];
    final RegExp imgRegex = RegExp(r'<img[^>]+src="([^">]+)"[^>]*>');
    final segments = content.split(imgRegex);
    final matches = imgRegex.allMatches(content);
    int matchIndex = 0;

    for (int i = 0; i < segments.length; i++) {
      // Add text segment
      if (segments[i].isNotEmpty) {
        final formattedText = _formatText(segments[i]);
        if (formattedText.isNotEmpty) {
          widgets.add(SelectableText(
            formattedText,
            style: TextStyle(
              fontSize: fontSize,
              height: lineHeight,
              color: textColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.justify,
          ));
        }
      }

      // Add image if there's a match
      if (matchIndex < matches.length && i == matchIndex) {
        final match = matches.elementAt(matchIndex);
        final fullMatch = match.group(0) ?? '';
        final imagePath = match.group(1);
        
        if (imagePath != null && images != null) {
          final isCover = _isCoverImage(fullMatch);
          final imageWidget = _buildImage(imagePath, isCover);
          if (imageWidget != null) {
            if (isCover) {
              // If it's a cover image, make it the only widget
              return [imageWidget];
            } else {
              widgets.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: imageWidget,
              ));
            }
          }
        }
        matchIndex++;
      }
    }

    return widgets;
  }


  Widget? _buildImage(String src, bool isCover) {
    // Remove any URL encoding
    final decodedSrc = Uri.decodeFull(src);
    
    // Try to find the image in the EPUB contents
    final imageFile = images?.entries.firstWhere(
      (entry) => entry.key.contains(decodedSrc) || decodedSrc.contains(entry.key),
      orElse: () => MapEntry('', epubx.EpubByteContentFile()),
    ).value;

    if (imageFile?.Content != null) {
      if (isCover) {
        // Cover image should fill the screen while maintaining aspect ratio
        return Container(
          width: screenSize.width,
          height: screenSize.height,
          color: Colors.black,
          child: Image.memory(
             Uint8List.fromList(imageFile!.Content!),
          fit: BoxFit.contain,
          ),
        );
      } else {
        // Regular inline images
        return ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 400,
          ),
          child: Image.memory(
             Uint8List.fromList(imageFile!.Content!),
          fit: BoxFit.contain,
          ),
        );
      }
    }
    return null;
  }

  String _formatText(String content) {
    // Remove excessive whitespace and newlines
    content = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();

    // Handle common HTML entities
    final entities = {
      '&nbsp;': ' ',
      '&quot;': '"',
      '&apos;': "'",
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&#160;': ' ',
    };

    entities.forEach((entity, replacement) {
      content = content.replaceAll(entity, replacement);
    });

    // Handle paragraph breaks
    content = content.replaceAll(RegExp(r'<p[^>]*>'), '\n\n');
    content = content.replaceAll('</p>', '');

    // Handle basic formatting
    content = content.replaceAll(RegExp(r'<br[^>]*>'), '\n');
    content = content.replaceAll(RegExp(r'<div[^>]*>'), '\n');
    content = content.replaceAll('</div>', '');

    // Remove remaining HTML tags (except img tags, which we handle separately)
    content = content.replaceAll(RegExp(r'<(?!img)[^>]+>'), '');

    // Normalize paragraph spacing
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    // Remove leading/trailing whitespace from each line
    content = content.split('\n').map((line) => line.trim()).join('\n');

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final contentWidgets = _parseContent(htmlContent);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: contentWidgets,
      ),
    );
  }
}