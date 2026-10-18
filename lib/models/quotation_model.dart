import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationLineItem {
  final String description;
  final int quantity;
  final double unitPrice;

  QuotationLineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  double get total => quantity * unitPrice;

  factory QuotationLineItem.fromMap(Map<String, dynamic> map) {
    return QuotationLineItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] is num) ? (map['quantity'] as num).toInt() : 1,
      unitPrice: (map['unitPrice'] is num)
          ? (map['unitPrice'] as num).toDouble()
          : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
    };
  }
}

class Quotation {
  final String id;
  final String quoteNumber; // e.g. QTE-2025-001
  final String agencyId;
  final String title;
  final String description;
  final String associatedDealId;
  final String associatedLeadId;
  final String associatedCompanyId;
  final String clientName;
  final String clientEmail;
  final String status; // 'Draft', 'Sent', 'Accepted', 'Rejected', 'Expired'
  final List<QuotationLineItem> items;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double discountAmount;
  final double finalTotal;
  final DateTime validityDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Quotation({
    required this.id,
    required this.quoteNumber,
    required this.agencyId,
    required this.title,
    this.description = '',
    this.associatedDealId = '',
    this.associatedLeadId = '',
    this.associatedCompanyId = '',
    required this.clientName,
    this.clientEmail = '',
    this.status = 'Draft',
    this.items = const [],
    required this.subtotal,
    this.taxPercent = 18.0,
    required this.taxAmount,
    this.discountAmount = 0.0,
    required this.finalTotal,
    required this.validityDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> statuses = [
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Expired',
  ];

  factory Quotation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = (data['items'] as List<dynamic>?)
            ?.map((e) => QuotationLineItem.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return Quotation(
      id: doc.id,
      quoteNumber: data['quoteNumber'] ?? '',
      agencyId: data['agencyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      associatedDealId: data['associatedDealId'] ?? '',
      associatedLeadId: data['associatedLeadId'] ?? '',
      associatedCompanyId: data['associatedCompanyId'] ?? '',
      clientName: data['clientName'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      status: data['status'] ?? 'Draft',
      items: rawItems,
      subtotal: (data['subtotal'] is num)
          ? (data['subtotal'] as num).toDouble()
          : 0.0,
      taxPercent: (data['taxPercent'] is num)
          ? (data['taxPercent'] as num).toDouble()
          : 18.0,
      taxAmount: (data['taxAmount'] is num)
          ? (data['taxAmount'] as num).toDouble()
          : 0.0,
      discountAmount: (data['discountAmount'] is num)
          ? (data['discountAmount'] as num).toDouble()
          : 0.0,
      finalTotal: (data['finalTotal'] is num)
          ? (data['finalTotal'] as num).toDouble()
          : 0.0,
      validityDate: (data['validityDate'] is Timestamp)
          ? (data['validityDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 14)),
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
      'quoteNumber': quoteNumber,
      'agencyId': agencyId,
      'title': title,
      'description': description,
      'associatedDealId': associatedDealId,
      'associatedLeadId': associatedLeadId,
      'associatedCompanyId': associatedCompanyId,
      'clientName': clientName,
      'clientEmail': clientEmail,
      'status': status,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'taxPercent': taxPercent,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'finalTotal': finalTotal,
      'validityDate': Timestamp.fromDate(validityDate),
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Quotation copyWith({
    String? title,
    String? description,
    String? associatedDealId,
    String? associatedLeadId,
    String? associatedCompanyId,
    String? clientName,
    String? clientEmail,
    String? status,
    List<QuotationLineItem>? items,
    double? subtotal,
    double? taxPercent,
    double? taxAmount,
    double? discountAmount,
    double? finalTotal,
    DateTime? validityDate,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id,
      quoteNumber: quoteNumber,
      agencyId: agencyId,
      title: title ?? this.title,
      description: description ?? this.description,
      associatedDealId: associatedDealId ?? this.associatedDealId,
      associatedLeadId: associatedLeadId ?? this.associatedLeadId,
      associatedCompanyId: associatedCompanyId ?? this.associatedCompanyId,
      clientName: clientName ?? this.clientName,
      clientEmail: clientEmail ?? this.clientEmail,
      status: status ?? this.status,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      finalTotal: finalTotal ?? this.finalTotal,
      validityDate: validityDate ?? this.validityDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
