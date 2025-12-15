// lib/models/followup_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DayEntry {
  final String day; // "الإثنين" ...
  final int from;
  final int to;
  final String review;
  final bool done;

  DayEntry({
    required this.day,
    required this.from,
    required this.to,
    required this.review,
    this.done = false,
  });

  factory DayEntry.fromMap(Map<String, dynamic> m) => DayEntry(
        day: m['day'] ?? '',
        from: (m['from'] ?? 1) as int,
        to: (m['to'] ?? 1) as int,
        review: m['review'] ?? '',
        done: m['done'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'day': day,
        'from': from,
        'to': to,
        'review': review,
        'done': done,
      };
}

class FollowUpModel {
  final String id; // id doc Firestore (vide pour new)
  final String studentId;
  final String profId;
  final DateTime date; // session date
  final String sura;
  final List<DayEntry> days; // length 7
  final String notes;
  final Timestamp createdAt;

  FollowUpModel({
    this.id = '',
    required this.studentId,
    required this.profId,
    required this.date,
    required this.sura,
    required this.days,
    this.notes = '',
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  factory FollowUpModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final daysList = (d['days'] as List<dynamic>?)?.map((e) => DayEntry.fromMap(Map<String, dynamic>.from(e))).toList() ?? [];
    return FollowUpModel(
      id: doc.id,
      studentId: d['studentId'] ?? '',
      profId: d['profId'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      sura: d['sura'] ?? '',
      days: daysList,
      notes: d['notes'] ?? '',
      createdAt: d['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'profId': profId,
        'date': Timestamp.fromDate(date),
        'sura': sura,
        'days': days.map((e) => e.toMap()).toList(),
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
