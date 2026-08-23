final _shareCodePattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

String buildClassroomShareUrl({
  required String baseUrl,
  required String shareCode,
}) {
  final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  return Uri.parse(
    normalizedBaseUrl,
  ).replace(queryParameters: {'class': shareCode}).toString();
}

String? sharedClassroomPath(Uri uri) {
  final shareCode = uri.queryParameters['class']?.trim();
  if (shareCode == null || !_shareCodePattern.hasMatch(shareCode)) return null;
  return '/class/$shareCode';
}
