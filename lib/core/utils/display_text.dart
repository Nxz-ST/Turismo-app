String titleCaseUserText(String? value, {String fallback = ''}) {
  final normalized = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (normalized.isEmpty) return fallback;
  return normalized.split(' ').map(_capitalizeWord).join(' ');
}

String sentenceCaseUserText(String? value, {String fallback = ''}) {
  final normalized = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  if (normalized.isEmpty) return fallback;
  final lower = normalized.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

String _capitalizeWord(String value) {
  final lower = value.toLowerCase();
  if (lower.isEmpty) return lower;
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}
