import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/lead_model.dart';
import '../models/deal_model.dart';
import '../models/task_model.dart';

class CsvExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// Export Leads to CSV
  static Future<void> exportLeads(List<Lead> leads) async {
    final List<List<dynamic>> rows = [
      [
        'Lead ID',
        'Full Name',
        'Company',
        'Email',
        'Phone',
        'Interested Service',
        'Estimated Budget',
        'Source',
        'Status',
        'Assigned To',
        'Next Follow-Up',
        'Created At'
      ]
    ];

    for (var lead in leads) {
      rows.add([
        lead.id,
        lead.fullName,
        lead.companyName,
        lead.email,
        lead.phone,
        lead.interestedService,
        lead.estimatedBudget,
        lead.source,
        lead.status,
        lead.assignedToName,
        lead.nextFollowUpDate != null
            ? _dateFormat.format(lead.nextFollowUpDate!)
            : 'None',
        _dateFormat.format(lead.createdAt),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(utf8.encode(csvData)),
      filename: 'leads_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
  }

  /// Export Deals to CSV
  static Future<void> exportDeals(List<Deal> deals, String currencySymbol) async {
    final List<List<dynamic>> rows = [
      [
        'Deal ID',
        'Title',
        'Company',
        'Contact',
        'Value ($currencySymbol)',
        'Stage',
        'Service Offered',
        'Assigned To',
        'Expected Close Date',
        'Lost Reason',
        'Created At'
      ]
    ];

    for (var deal in deals) {
      rows.add([
        deal.id,
        deal.title,
        deal.companyName,
        deal.contactName,
        deal.dealValue,
        deal.stage,
        deal.serviceOffered,
        deal.assignedToName,
        DateFormat('yyyy-MM-dd').format(deal.expectedCloseDate),
        deal.lostReason,
        _dateFormat.format(deal.createdAt),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(utf8.encode(csvData)),
      filename: 'deals_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
  }

  /// Export Tasks to CSV
  static Future<void> exportTasks(List<TaskItem> tasks) async {
    final List<List<dynamic>> rows = [
      [
        'Task ID',
        'Title',
        'Type',
        'Status',
        'Priority',
        'Due Date',
        'Assigned To',
        'Linked Entity',
        'Created At'
      ]
    ];

    for (var task in tasks) {
      rows.add([
        task.id,
        task.title,
        task.type,
        task.status,
        task.priority,
        _dateFormat.format(task.dueDate),
        task.assignedToName,
        task.linkedEntityTitle.isNotEmpty ? task.linkedEntityTitle : 'None',
        _dateFormat.format(task.createdAt),
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(utf8.encode(csvData)),
      filename: 'tasks_export_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
    );
  }
}
