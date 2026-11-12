## 0.1.0

Initial Version of library

- Initial release of mini_pdf_epub_reader library.


## 0.1.1 

Add zoom functionality and header

- Add ability for users to zoom current page


## 0.1.2 

Add dark theme

- Add support for dark theme on tablet and mobile


## 0.2.0

Continuous PDF scrolling and EPUB support

- Switch the PDF engine from pdfx to pdfrx (PDFium)
- PDFs scroll continuously with pages on a canvas, sharp pinch-zoom and double-tap to zoom
- Thumbnails render lazily from the open document and the sidebar follows the current page
- Add EPUB support: reflowable sections, embedded images, internal links, text size controls and a table of contents sidebar
- Load documents without copying them into the app documents directory
- Fix the PDF being opened once per thumbnail and never closed
- Fix the dark-mode accent colour never applying
- Reload when `source` or `type` changes
- Remove the path_provider dependency
