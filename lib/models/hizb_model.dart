// lib/models/hizb_model.dart

class HizbModel {
  final int hizbNumber;
  final String startSura;
  final int startSuraNumber;
  final int startVerse;
  final String endSura;
  final int endSuraNumber;
  final int endVerse;
  final int juzNumber;

  HizbModel({
    required this.hizbNumber,
    required this.startSura,
    required this.startSuraNumber,
    required this.startVerse,
    required this.endSura,
    required this.endSuraNumber,
    required this.endVerse,
    required this.juzNumber,
  });

  factory HizbModel.fromMap(Map<String, dynamic> map) {
    return HizbModel(
      hizbNumber: map['hizbNumber'] ?? 0,
      startSura: map['startSura'] ?? '',
      startSuraNumber: map['startSuraNumber'] ?? 0,
      startVerse: map['startVerse'] ?? 0,
      endSura: map['endSura'] ?? '',
      endSuraNumber: map['endSuraNumber'] ?? 0,
      endVerse: map['endVerse'] ?? 0,
      juzNumber: map['juzNumber'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hizbNumber': hizbNumber,
      'startSura': startSura,
      'startSuraNumber': startSuraNumber,
      'startVerse': startVerse,
      'endSura': endSura,
      'endSuraNumber': endSuraNumber,
      'endVerse': endVerse,
      'juzNumber': juzNumber,
    };
  }

  // Vérifie si un verset donné est dans ce hizb
  bool containsVerse(int suraNumber, int verseNumber) {
    if (startSuraNumber == endSuraNumber) {
      // Même sourate
      return suraNumber == startSuraNumber &&
          verseNumber >= startVerse &&
          verseNumber <= endVerse;
    } else {
      // Plusieurs sourates
      if (suraNumber == startSuraNumber) {
        return verseNumber >= startVerse;
      } else if (suraNumber == endSuraNumber) {
        return verseNumber <= endVerse;
      } else {
        return suraNumber > startSuraNumber && suraNumber < endSuraNumber;
      }
    }
  }

  @override
  String toString() {
    return 'Hizb $hizbNumber: $startSura ($startVerse) → $endSura ($endVerse)';
  }
}