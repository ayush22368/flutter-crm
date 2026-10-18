import 'package:cloud_firestore/cloud_firestore.dart';

class TaskItem {
  final String id;
  final String agencyId;
  final String title;
  final String description;
  final String type; // Phone call, Meeting, Email follow-up, General task
  final String status; // Pending, In Progress, Completed, Cancelled
  final String priority; // High, Medium, Low
  final DateTime dueDate;
  final String assignedToUid;
  final String assignedToName;
  final String linkedEntityType; // 'lead', 'contact', 'deal', 'company', 'none'
  final String linkedEntityId;
  final String linkedEntityTitle;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskItem({
    required this.id,
    required this.agencyId,
    required this.title,
    this.description = '',
    this.type = 'General task',
    this.status = 'Pending',
    this.priority = 'Medium',
    required this.dueDate,
    this.assignedToUid = '',
    this.assignedToName = '',
    this.linkedEntityType = 'none',
    this.linkedEntityId = '',
    this.linkedEntityTitle = '',
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> types = [
    'Phone call',
    'Meeting',
    'Email follow-up',
    'General task',
  ];

  static const List<String> statuses = [
    'Pending',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  static const List<String> priorities = [
    'High',
    'Medium',
    'Low',
  ];

  bool get isCompleted => status == 'Completed';
  bool get isOverdue {
    if (isCompleted || status == 'Cancelled') return false;
    return dueDate.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (isCompleted || status == 'Cancelled') return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }

  factory TaskItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TaskItem(
      id: doc.id,
      agencyId: data['agencyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'General task',
      status: data['status'] ?? 'Pending',
      priority: data['priority'] ?? 'Medium',
      dueDate: (data['dueDate'] is Timestamp)
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      assignedToUid: data['assignedToUid'] ?? '',
      assignedToName: data['assignedToName'] ?? '',
      linkedEntityType: data['linkedEntityType'] ?? 'none',
      linkedEntityId: data['linkedEntityId'] ?? '',
      linkedEntityTitle: data['linkedEntityTitle'] ?? '',
      completedAt: (data['completedAt'] is Timestamp)
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
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
      'description': description,
      'type': type,
      'status': status,
      'priority': priority,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'linkedEntityType': linkedEntityType,
      'linkedEntityId': linkedEntityId,
      'linkedEntityTitle': linkedEntityTitle,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskItem copyWith({
    String? title,
    String? description,
    String? type,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? assignedToUid,
    String? assignedToName,
    String? linkedEntityType,
    String? linkedEntityId,
    String? linkedEntityTitle,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id,
      agencyId: agencyId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      assignedToUid: assignedToUid ?? this.assignedToUid,
      assignedToName: assignedToName ?? this.assignedToName,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      linkedEntityTitle: linkedEntityTitle ?? this.linkedEntityTitle,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
