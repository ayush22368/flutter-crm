import 'package:cloud_firestore/cloud_firestore.dart';

class DealStageHistory {
  final String fromStage;
  final String toStage;
  final DateTime timestamp;
  final String changedByUid;
  final String changedByName;
  final String note;

  DealStageHistory({
    required this.fromStage,
    required this.toStage,
    required this.timestamp,
    this.changedByUid = '',
    this.changedByName = '',
    this.note = '',
  });

  factory DealStageHistory.fromMap(Map<String, dynamic> map) {
    return DealStageHistory(
      fromStage: map['fromStage'] ?? '',
      toStage: map['toStage'] ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : (map['timestamp'] is String)
              ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      changedByUid: map['changedByUid'] ?? '',
      changedByName: map['changedByName'] ?? '',
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromStage': fromStage,
      'toStage': toStage,
      'timestamp': Timestamp.fromDate(timestamp),
      'changedByUid': changedByUid,
      'changedByName': changedByName,
      'note': note,
    };
  }
}

class Deal {
  final String id;
  final String agencyId;
  final String title;
  final double dealValue;
  final DateTime expectedCloseDate;
  final String stage;
  final String assignedToUid;
  final String assignedToName;
  final String serviceOffered;
  final String associatedLeadId;
  final String associatedContactId;
  final String associatedCompanyId;
  final String companyName;
  final String contactName;
  final String lostReason;
  final List<DealStageHistory> stageHistory;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deal({
    required this.id,
    required this.agencyId,
    required this.title,
    required this.dealValue,
    required this.expectedCloseDate,
    this.stage = 'New Lead',
    this.assignedToUid = '',
    this.assignedToName = '',
    this.serviceOffered = 'Web Development',
    this.associatedLeadId = '',
    this.associatedContactId = '',
    this.associatedCompanyId = '',
    this.companyName = '',
    this.contactName = '',
    this.lostReason = '',
    this.stageHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> stages = [
    'New Lead',
    'Contacted',
    'Qualified',
    'Proposal Sent',
    'Negotiation',
    'Won',
    'Lost',
  ];

  bool get isWon => stage == 'Won';
  bool get isLost => stage == 'Lost';
  bool get isOpen => !isWon && !isLost;

  factory Deal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final historyList = (data['stageHistory'] as List<dynamic>?)
            ?.map((e) => DealStageHistory.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return Deal(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      title: data['title'] ?? '',
      dealValue: (data['dealValue'] is num)
          ? (data['dealValue'] as num).toDouble()
          : 0.0,
      expectedCloseDate: (data['expectedCloseDate'] is Timestamp)
          ? (data['expectedCloseDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      stage: data['stage'] ?? 'New Lead',
      assignedToUid: data['assignedToUid'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      serviceOffered: data['serviceOffered'] ?? 'Web Development',
      associatedLeadId: data['associatedLeadId'] ?? '',
      associatedContactId: data['associatedContactId'] ?? '',
      associatedCompanyId: data['associatedCompanyId'] ?? '',
      companyName: data['companyName'] ?? '',
      contactName: data['contactName'] ?? '',
      lostReason: data['lostReason'] ?? '',
      stageHistory: historyList,
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
      'title': title,
      'dealValue': dealValue,
      'expectedCloseDate': Timestamp.fromDate(expectedCloseDate),
      'stage': stage,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'serviceOffered': serviceOffered,
      'associatedLeadId': associatedLeadId,
      'associatedContactId': associatedContactId,
      'associatedCompanyId': associatedCompanyId,
      'companyName': companyName,
      'contactName': contactName,
      'lostReason': lostReason,
      'stageHistory': stageHistory.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Deal copyWith({
    String? title,
    double? dealValue,
    DateTime? expectedCloseDate,
    String? stage,
    String? assignedToUid,
    String? assignedToName,
    String? serviceOffered,
    String? associatedLeadId,
    String? associatedContactId,
    String? associatedCompanyId,
    String? companyName,
    String? contactName,
    String? lostReason,
    List<DealStageHistory>? stageHistory,
    DateTime? updatedAt,
  }) {
    return Deal(
      id: id,
      agencyId: agencyId,
      title: title ?? this.title,
      dealValue: dealValue ?? this.dealValue,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      stage: stage ?? this.stage,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToName: assignedToName ?? this.assignedToName,
      serviceOffered: serviceOffered ?? this.serviceOffered,
      associatedLeadId: associatedLeadId ?? this.associatedLeadId,
      associatedContactId: associatedContactId ?? this.associatedContactId,
      associatedCompanyId: associatedCompanyId ?? this.associatedCompanyId,
      companyName: companyName ?? this.companyName,
      contactName: contactName ?? this.contactName,
      lostReason: lostReason ?? this.lostReason,
      stageHistory: stageHistory ?? this.stageHistory,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
