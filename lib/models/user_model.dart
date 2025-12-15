// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String role; // "admin", "prof", "etudiant"
  final DateTime createdAt;
  final bool isActive;
  
  // Champs facultatifs (tous)
  final String? profileImage;
  final String? city;
  
  // Champs spécifiques ÉTUDIANT
  final int? age;
  final DateTime? dateInscription;
  final int? oldHafd;      // Ahzab appris AVANT Irtaqi
  final int? newHafd;      // Ahzab appris DANS Irtaqi (auto)
  final int? totalHafd;    // Total oldHafd + newHafd
  final String? groupId;
  
  // Champs spécifiques PROF
  final List<String>? groupIds;
  final String? speciality;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.profileImage,
    this.city,
    this.age,
    this.dateInscription,
    this.oldHafd,
    this.newHafd,
    this.totalHafd,
    this.groupId,
    this.groupIds,
    this.speciality,
  });

  // Getters utiles
  bool get isStudent => role == 'etudiant';
  bool get isProf => role == 'prof';
  bool get isAdmin => role == 'admin';
  
  String get fullName => '$firstName $lastName';

  factory UserModel.fromMap(String id, Map<String, dynamic> m) {
    return UserModel(
      id: id,
      firstName: m['firstName'] ?? '',
      lastName: m['lastName'] ?? '',
      phone: m['phone'] ?? '',
      email: m['email'] ?? '',
      role: m['role'] ?? 'etudiant',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: m['isActive'] ?? true,
      profileImage: m['profileImage'],
      city: m['city'],
      age: m['age'],
      dateInscription: (m['dateInscription'] as Timestamp?)?.toDate(),
      oldHafd: m['oldHafd'],
      newHafd: m['newHafd'],
      totalHafd: m['totalHafd'],
      groupId: m['groupId'],
      groupIds: m['groupIds'] != null ? List<String>.from(m['groupIds']) : null,
      speciality: m['speciality'],
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> data = {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };

    // Ajouter les champs facultatifs s'ils existent
    if (profileImage != null) data['profileImage'] = profileImage;
    if (city != null) data['city'] = city;
    
    // Champs étudiant
    if (isStudent) {
      if (age != null) data['age'] = age;
      if (dateInscription != null) {
        data['dateInscription'] = Timestamp.fromDate(dateInscription!);
      }
      if (oldHafd != null) data['oldHafd'] = oldHafd;
      if (newHafd != null) data['newHafd'] = newHafd;
      if (totalHafd != null) data['totalHafd'] = totalHafd;
      if (groupId != null) data['groupId'] = groupId;
    }
    
    // Champs prof
    if (isProf) {
      if (groupIds != null) data['groupIds'] = groupIds;
      if (speciality != null) data['speciality'] = speciality;
    }

    return data;
  }
}