class AppVersionModel {
  final String version;
  final int buildNumber;
  final String title;
  final String releaseNotes;
  final List<String> highlights;
  final DateTime releasedAt;
  final bool isMandatory;
  final String? minSupportedVersion;

  AppVersionModel({
    required this.version,
    required this.buildNumber,
    this.title = 'Mise à jour disponible ! 🎉',
    this.releaseNotes = '',
    this.highlights = const [],
    required this.releasedAt,
    this.isMandatory = false,
    this.minSupportedVersion,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      version: json['version'] as String? ?? '1.0.0',
      buildNumber: json['buildNumber'] is int
          ? json['buildNumber'] as int
          : int.tryParse(json['buildNumber']?.toString() ?? '100') ?? 100,
      title: json['title'] as String? ?? 'Mise à jour disponible ! 🎉',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      releasedAt: json['releasedAt'] != null
          ? DateTime.tryParse(json['releasedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMandatory: json['isMandatory'] as bool? ?? false,
      minSupportedVersion: json['minSupportedVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'title': title,
      'releaseNotes': releaseNotes,
      'highlights': highlights,
      'releasedAt': releasedAt.toIso8601String(),
      'isMandatory': isMandatory,
      if (minSupportedVersion != null) 'minSupportedVersion': minSupportedVersion,
    };
  }

  /// Compares build number and semver to check if this version is newer
  bool isNewerThan(int currentBuild, [String? currentVer]) {
    if (buildNumber > currentBuild) return true;
    if (currentVer != null && version != currentVer) {
      final currentParts = currentVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final newParts = version.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      for (int i = 0; i < 3; i++) {
        final cur = i < currentParts.length ? currentParts[i] : 0;
        final next = i < newParts.length ? newParts[i] : 0;
        if (next > cur) return true;
        if (next < cur) return false;
      }
    }
    return false;
  }
}
