import 'package:cloud_firestore/cloud_firestore.dart';

class Agency {
  final String id;
  final String name;
  final String description;
  final String businessEmail;
  final String phone;
  final String website;
  final String address;
  final String currencySymbol;
  final double defaultTaxPercent;
  final String inviteCode;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Agency({
    required this.id,
    required this.name,
    this.description = '',
    this.businessEmail = '',
    this.phone = '',
    this.website = '',
    this.address = '',
    this.currencySymbol = '\$',
    this.defaultTaxPercent = 18.0,
    required this.inviteCode,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Agency(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      businessEmail: data['businessEmail'] ?? '',
      phone: data['phone'] ?? '',
      website: data['website'] ?? '',
      address: data['address'] ?? '',
      currencySymbol: data['currencySymbol'] ?? '\$',
      defaultTaxPercent: (data['defaultTaxPercent'] is num)
          ? (data['defaultTaxPercent'] as num).toDouble()
          : 18.0,
      inviteCode: data['inviteCode'] ?? '',
      ownerId: data['ownerId'] ?? '',
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
      'name': name,
      'description': description,
      'businessEmail': businessEmail,
      'phone': phone,
      'website': website,
      'address': address,
      'currencySymbol': currencySymbol,
      'defaultTaxPercent': defaultTaxPercent,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Agency copyWith({
    String? name,
    String? description,
    String? businessEmail,
    String? phone,
    String? website,
    String? address,
    String? currencySymbol,
    double? defaultTaxPercent,
    String? inviteCode,
    String? ownerId,
    DateTime? updatedAt,
  }) {
    return Agency(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      businessEmail: businessEmail ?? this.businessEmail,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      defaultTaxPercent: defaultTaxPercent ?? this.defaultTaxPercent,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class AgencyMember {
  final String uid;
  final String agencyId;
  final String email;
  final String displayName;
  final String photoUrl;
  final String role; // 'owner', 'admin', 'employee'
  final bool isActive;
  final DateTime joinedAt;

  AgencyMember({
    required this.uid,
    required this.agencyId,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.role = 'employee',
    this.isActive = true,
    required this.joinedAt,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin' || role == 'owner';
  bool get isEmployee => role == 'employee';

  factory AgencyMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AgencyMember(
      uid: doc.id,
      agencyId: data['agencyId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      role: data['role'] ?? 'employee',
      isActive: data['isActive'] ?? true,
      joinedAt: (data['joinedAt'] is Timestamp)
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyId': agencyId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}
