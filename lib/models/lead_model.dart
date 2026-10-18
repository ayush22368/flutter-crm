import 'package:cloud_firestore/cloud_firestore.dart';

class Lead {
  final String id;
  final String agencyId;
  final String fullName;
  final String companyName;
  final String email;
  final String phone;
  final String interestedService;
  final double estimatedBudget;
  final String source; // Website, Referral, Social media, Phone call, Email, Other
  final String status; // New, Contacted, Qualified, Unqualified
  final String assignedToUid;
  final String assignedToName;
  final String notes;
  final DateTime? nextFollowUpDate;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.agencyId,
    required this.fullName,
    this.companyName = '',
    required this.email,
    this.phone = '',
    this.interestedService = 'Web Development',
    this.estimatedBudget = 0.0,
    this.source = 'Website',
    this.status = 'New',
    this.assignedToUid = '',
    this.assignedToName = '',
    this.notes = '',
    this.nextFollowUpDate,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> sources = [
    'Website',
    'Referral',
    'Social media',
    'Phone call',
    'Email',
    'Other',
  ];

  static const List<String> statuses = [
    'New',
    'Contacted',
    'Qualified',
    'Unqualified',
  ];

  static const List<String> services = [
    'Web Development',
    'Mobile Application',
    'Custom Software',
    'UI/UX Design',
    'Maintenance & Support',
    'Cloud & DevOps',
    'Other',
  ];

  factory Lead.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Lead(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      fullName: data['fullName'] ?? '',
      companyName: data['companyName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      interestedService: data['interestedService'] ?? 'Web Development',
      estimatedBudget: (data['estimatedBudget'] is num)
          ? (data['estimatedBudget'] as num).toDouble()
          : 0.0,
      source: data['source'] ?? 'Website',
      status: data['status'] ?? 'New',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      notes: data['notes'] ?? '',
      nextFollowUpDate: (data['nextFollowUpDate'] is Timestamp)
          ? (data['nextFollowUpDate'] as Timestamp).toDate()
          : null,
      isArchived: data['isArchived'] ?? false,
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
      'companyName': companyName,
      'email': email,
      'phone': phone,
      'interestedService': interestedService,
      'estimatedBudget': estimatedBudget,
      'source': source,
      'status': status,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'notes': notes,
      'nextFollowUpDate': nextFollowUpDate != null
          ? Timestamp.fromDate(nextFollowUpDate!)
          : null,
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Lead copyWith({
    String? fullName,
    String? companyName,
    String? email,
    String? phone,
    String? interestedService,
    double? estimatedBudget,
    String? source,
    String? status,
    String? assignedToUid,
    String? assignedToName,
    String? notes,
    DateTime? nextFollowUpDate,
    bool? isArchived,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id,
      agencyId: agencyId,
      fullName: fullName ?? this.fullName,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      interestedService: interestedService ?? this.interestedService,
      estimatedBudget: estimatedBudget ?? this.estimatedBudget,
      source: source ?? this.source,
      status: status ?? this.status,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToName: assignedToName ?? this.assignedToName,
      notes: notes ?? this.notes,
      nextFollowUpDate: nextFollowUpDate ?? this.nextFollowUpDate,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
