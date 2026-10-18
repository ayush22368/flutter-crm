import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  final String id;
  final String agencyId;
  final String type; // 'Call', 'Meeting', 'Email', 'Note', 'Stage Change', 'System'
  final String title;
  final String description;
  final String linkedEntityType; // 'lead', 'contact', 'deal', 'company', 'none'
  final String linkedEntityId;
  final String linkedEntityTitle;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.agencyId,
    required this.type,
    required this.title,
    this.description = '',
    this.linkedEntityType = 'none',
    this.linkedEntityId = '',
    this.linkedEntityTitle = '',
    this.createdByUid = '',
    this.createdByName = '',
    required this.createdAt,
  });

  static const List<String> types = [
    'Call',
    'Meeting',
    'Email',
    'Note',
    'Stage Change',
    'System',
  ];

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ActivityItem(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      type: data['type'] ?? 'Note',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      linkedEntityType: data['linkedEntityType'] ?? 'none',
      linkedEntityId: data['linkedEntityId'] ?? '',
      linkedEntityTitle: data['linkedEntityTitle'] ?? '',
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'agencyId': agencyId,
      'type': type,
      'title': title,
      'description': description,
      'linkedEntityType': linkedEntityType,
      'linkedEntityId': linkedEntityId,
      'linkedEntityTitle': linkedEntityTitle,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
