import 'package:cloud_firestore/cloud_firestore.dart';

class Contact {
  final String id;
  final String agencyId;
  final String fullName;
  final String email;
  final String phone;
  final String jobTitle;
  final String companyId;
  final String companyName;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.agencyId,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.jobTitle = '',
    this.companyId = '',
    this.companyName = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Contact(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      notes: data['notes'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyId': agencyId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'jobTitle': jobTitle,
      'companyId': companyId,
      'companyName': companyName,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Contact copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? jobTitle,
    String? companyId,
    String? companyName,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id,
      agencyId: agencyId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
