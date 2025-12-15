// lib/models/student_model.dart
class StudentModel {
  final String userId; // lien vers users collection (uid)
  final int age;
  final DateTime dateInscription;
  final int hafdCurrent; // مقدار الحفظ الحالي (0..60)

  StudentModel({
    required this.userId,
    required this.age,
    required this.dateInscription,
    required this.hafdCurrent,
  });

  factory StudentModel.fromMap(Map<String, dynamic> m) => StudentModel(
        userId: m['userId'] ?? '',
        age: (m['age'] ?? 0) as int,
        dateInscription: (m['dateInscription'] as DateTime?) ?? DateTime.now(),
        hafdCurrent: (m['hafdCurrent'] ?? 0) as int,
      );

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'age': age,
        'dateInscription': dateInscription,
        'hafdCurrent': hafdCurrent,
      };
}
