# Mini PDF & EPUB Viewer

**Mini PDF & EPUB Viewer** is a Flutter widget designed to provide a seamless document viewing experience with support for PDF files and (upcoming) EPUB format. It offers an intuitive interface with thumbnail navigation, smooth page transitions, and customizable viewing options, making it perfect for document reader applications, e-book apps, or any Flutter project requiring document viewing capabilities.

## Examples
| ![Mini Viewer](doc/src/assets/example/example.gif) |
|:--------------------------------------------------------------------:|
| Mini PDF Viewer Example                                            |

## Features

- **Multiple Document Sources**: Load documents from various sources:
  - Local files
  - Network URLs
  - Asset bundles
- **Thumbnail Navigation**: Quick navigation through document pages with a customizable thumbnail sidebar
- **Smooth Page Transitions**: Animated page transitions with customizable duration and curves
- **Responsive Layout**: Adapts to different screen sizes and orientations
- **Error Handling**: Comprehensive error handling with user-friendly error messages and retry options
- **Loading States**: Clear loading indicators for both document and thumbnails
- **Custom Styling**: Customizable thumbnail sizes and selection colors

## Installation

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  mini_pdf_epub_viewer: ^0.1.0
```

## Usage

First, import the package:

```dart
import 'package:mini_pdf_epub_viewer/mini_pdf_epub_viewer.dart';
```

### Load a Local File

```dart
DocumentViewer(
  source: DocumentSource(
    path: '/path/to/document.pdf',
    sourceType: DocumentSourceType.file,
  ),
  type: DocumentType.pdf,
);
```

### Load from Network

```dart
DocumentViewer(
  source: DocumentSource(
    path: 'https://example.com/document.pdf',
    sourceType: DocumentSourceType.network,
    headers: {'Authorization': 'Bearer token'}, // Optional headers
  ),
  type: DocumentType.pdf,
);
```

### Load from Assets

```dart
DocumentViewer(
  source: DocumentSource(
    path: 'assets/document.pdf',
    sourceType: DocumentSourceType.asset,
  ),
  type: DocumentType.pdf,
);
```

## Customization

The viewer can be customized with various properties:

```dart
DocumentViewer(
  source: DocumentSource(
    path: '/path/to/document.pdf',
    sourceType: DocumentSourceType.file,
  ),
  type: DocumentType.pdf,
  thumbnailWidth: 200,
  showThumbnails: true,
  selectedThumbnailColor: Colors.blue,
  pageTransitionDuration: Duration(milliseconds: 300),
  pageTransitionCurve: Curves.easeInOut,
);
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| source | DocumentSource | required | Configuration for the document source |
| type | DocumentType | required | Type of document (PDF/EPUB) |
| thumbnailWidth | double | 200 | Width of thumbnail sidebar |
| showThumbnails | bool | true | Whether to show thumbnails |
| selectedThumbnailColor | Color | Colors.blue | Color of selected thumbnail |
| pageTransitionDuration | Duration | 300ms | Duration of page transitions |
| pageTransitionCurve | Curve | Curves.easeInOut | Animation curve for transitions |

## Maintainers

- [Davies Kwarteng](https://github.com/davies-k)

## License

```
MIT License

Copyright (c) 2024 Davies Kwarteng

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```