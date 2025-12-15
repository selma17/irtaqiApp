// lib/models/group_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleSlot {
  final String day;
  final String startTime;
  final String endTime;

  ScheduleSlot({
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    return ScheduleSlot(
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  @override
  String toString() {
    return '$day: $startTime - $endTime';
  }
}

class GroupModel {
  final String id;
  final String name;
  final String profId;
  final List<ScheduleSlot> schedule;
  final List<String> studentIds;
  final int maxStudents;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.profId,
    required this.schedule,
    required this.studentIds,
    this.maxStudents = 20,
    required this.createdAt,
  });

  factory GroupModel.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<ScheduleSlot> scheduleList = [];
    if (data['schedule'] != null) {
      scheduleList = (data['schedule'] as List<dynamic>)
          .map((slot) => ScheduleSlot.fromMap(Map<String, dynamic>.from(slot)))
          .toList();
    }

    List<String> studentIdsList = [];
    if (data['studentIds'] != null) {
      studentIdsList = List<String>.from(data['studentIds']);
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      profId: data['profId'] ?? '',
      schedule: scheduleList,
      studentIds: studentIdsList,
      maxStudents: data['maxStudents'] ?? 20,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profId': profId,
      'schedule': schedule.map((slot) => slot.toMap()).toList(),
      'studentIds': studentIds,
      'maxStudents': maxStudents,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Getters utiles
  int get currentStudentsCount => studentIds.length;
  bool get isFull => currentStudentsCount >= maxStudents;
  int get availableSpots => maxStudents - currentStudentsCount;
  double get fillPercentage => (currentStudentsCount / maxStudents) * 100;
}