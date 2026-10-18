import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String agencyId;
  final String name;
  final String industry;
  final String website;
  final String email;
  final String phone;
  final String address;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.agencyId,
    required this.name,
    this.industry = 'Technology',
    this.website = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Company(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      name: data['name'] ?? '',
      industry: data['industry'] ?? 'Technology',
      website: data['website'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
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
      'name': name,
      'industry': industry,
      'website': website,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Company copyWith({
    String? name,
    String? industry,
    String? website,
    String? email,
    String? phone,
    String? address,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id,
      agencyId: agencyId,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      website: website ?? this.website,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
