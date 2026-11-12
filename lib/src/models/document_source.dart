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

  /// The file name shown in the viewer header, without any URL query.
  String get displayName {
    if (sourceType == DocumentSourceType.network) {
      final segments = Uri.tryParse(path)?.pathSegments ?? const [];
      final name = segments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
      if (name.isNotEmpty) return Uri.decodeComponent(name);
    }
    return path.split(RegExp(r'[/\\]')).last;
  }

  @override
  bool operator ==(Object other) =>
      other is DocumentSource &&
      other.path == path &&
      other.sourceType == sourceType;

  @override
  int get hashCode => Object.hash(path, sourceType);
}
