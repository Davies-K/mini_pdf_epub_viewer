import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/document_source.dart';
import 'read_file_stub.dart' if (dart.library.io) 'read_file_io.dart';

/// Loads the whole document described by [source] into memory.
Future<Uint8List> loadDocumentBytes(DocumentSource source) async {
  switch (source.sourceType) {
    case DocumentSourceType.asset:
      final data = await rootBundle.load(source.path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    case DocumentSourceType.file:
      return readFileBytes(source.path);
    case DocumentSourceType.network:
      final response =
          await http.get(Uri.parse(source.path), headers: source.headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
      return response.bodyBytes;
  }
}
