// lib/utils/validators.dart
bool validateDayEntry(int from, int to, int maxAyah) {
  if (from < 1 || to < 1) return false;
  if (from > maxAyah || to > maxAyah) return false;
  if (to < from) return false;
  return true;
}
