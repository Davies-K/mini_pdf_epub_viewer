enum DocumentSourceType { asset, file, network }

class DocumentSource {
  final String path;
  final DocumentSourceType sourceType;
  final Map<String, String>? headers;

  const DocumentSource.asset(this.path)
      : sourceType = DocumentSourceType.asset,
        headers = null;

  const DocumentSource.file(this.path)
      : sourceType = DocumentSourceType.file,
        headers = null;

  const DocumentSource.network(this.path, {this.headers})
      : sourceType = DocumentSourceType.network;
}
