import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/quotation_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_theme.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  String _statusFilter = 'All';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();
    final agency = auth.currentAgency;
    final currency = agency?.currencySymbol ?? '\$';

    final filteredQuotes = crm.quotations.where((q) {
      if (_statusFilter != 'All' && q.status != _statusFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quotations & Proposals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create line-item quotes with tax and download branded agency PDFs.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.note_add, size: 18),
                  label: const Text('Create Quotation'),
                  onPressed: () => _showCreateQuotationDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _statusFilter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...Quotation.statuses]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Status: $s'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quotations List
            Expanded(
              child: filteredQuotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.request_quote_outlined,
                              size: 48, color: AppTheme.textLight),
                          const SizedBox(height: 12),
                          const Text(
                            'No quotations created yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Generate professional software proposals with custom line items and tax.',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Create Quotation'),
                            onPressed: () => _showCreateQuotationDialog(context),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      child: ListView.separated(
                        itemCount: filteredQuotes.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: AppTheme.borderLight, height: 1),
                        itemBuilder: (context, index) {
                          final quote = filteredQuotes[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description,
                                  color: AppTheme.primary, size: 22),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  quote.quoteNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  quote.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 14,
                                children: [
                                  Text('Client: ${quote.clientName}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted)),
                                  Text(
                                      '• Items: ${quote.items.length}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textMuted)),
                                  Text(
                                      '• Valid until: ${_dateFormat.format(quote.validityDate)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight)),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Total Amount
                                Text(
                                  '$currency${NumberFormat("#,##0.00").format(quote.finalTotal)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Status Dropdown
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(quote.status)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: DropdownButton<String>(
                                    value: quote.status,
                                    underline: const SizedBox.shrink(),
                                    icon: Icon(Icons.arrow_drop_down,
                                        size: 16,
                                        color: _statusColor(quote.status)),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(quote.status),
                                    ),
                                    items: Quotation.statuses
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (newStatus) {
                                      if (newStatus != null) {
                                        crm.updateQuotationStatus(
                                            quote.id, newStatus);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Download PDF Button
                                IconButton(
                                  tooltip: 'Download PDF Quotation',
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: AppTheme.danger),
                                  onPressed: () async {
                                    if (agency != null) {
                                      await PdfService
                                          .generateAndDownloadQuotation(
                                        agency: agency,
                                        quotation: quote,
                                      );
                                    }
                                  },
                                ),
                                if (auth.isAdmin)
                                  IconButton(
                                    tooltip: 'Delete Quotation',
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppTheme.textLight),
                                    onPressed: () {
                                      crm.deleteQuotation(quote.id);
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // CREATE QUOTATION DIALOG WITH DYNAMIC LINE ITEMS
  // ----------------------------------------------------

  void _showCreateQuotationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();
    final agency = auth.currentAgency;
    final currency = agency?.currencySymbol ?? '\$';

    final quoteNum =
        'QTE-${DateTime.now().year}-${(crm.quotations.length + 1).toString().padLeft(3, '0')}';

    final titleController = TextEditingController(text: 'Custom Software Solution');
    final clientNameController = TextEditingController();
    final clientEmailController = TextEditingController();
    final descriptionController = TextEditingController();
    final taxPercentController =
        TextEditingController(text: (agency?.defaultTaxPercent ?? 18.0).toString());
    final discountController = TextEditingController(text: '0');
    final notesController = TextEditingController(
      text: 'Payment terms: 50% upfront, 50% on milestone sign-off.\nValidity: 14 days.',
    );

    DateTime validity = DateTime.now().add(const Duration(days: 14));

    // Dynamic line items
    final List<Map<String, dynamic>> lineItems = [
      {'desc': 'Frontend UI/UX Development (Flutter Web)', 'qty': 1, 'price': 3500.0},
      {'desc': 'Backend Architecture & API Integration (Firebase)', 'qty': 1, 'price': 3000.0},
      {'desc': 'QA Testing & Production Deployment', 'qty': 1, 'price': 1500.0},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double subtotal = 0.0;
          for (var item in lineItems) {
            subtotal += (item['qty'] as int) * (item['price'] as double);
          }

          final taxPct = double.tryParse(taxPercentController.text) ?? 0.0;
          final discount = double.tryParse(discountController.text) ?? 0.0;
          final taxAmount = (subtotal * taxPct) / 100.0;
          final finalTotal = (subtotal + taxAmount - discount).clamp(0.0, double.infinity);

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New Quotation'),
                Text(
                  quoteNum,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary),
                ),
              ],
            ),
            content: SizedBox(
              width: 640,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Project / Quote Title *',
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter title'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: clientNameController,
                              decoration: const InputDecoration(
                                labelText: 'Client / Company Name *',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter client name'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: clientEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Client Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Valid Until', style: TextStyle(fontSize: 12)),
                              subtitle: Text(DateFormat('MMM dd, yyyy').format(validity)),
                              trailing: IconButton(
                                icon: const Icon(Icons.calendar_today, size: 18),
                                onPressed: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: validity,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setDialogState(() => validity = d);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Line Items Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Service Deliverables & Line Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textMain,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Line Item'),
                            onPressed: () {
                              setDialogState(() {
                                lineItems.add({
                                  'desc': 'Software Development Service',
                                  'qty': 1,
                                  'price': 1000.0,
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ...List.generate(lineItems.length, (i) {
                        final item = lineItems[i];
                        final itemTotal =
                            (item['qty'] as int) * (item['price'] as double);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  initialValue: item['desc'],
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'Deliverable description',
                                  ),
                                  onChanged: (v) => item['desc'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  initialValue: '${item['qty']}',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Qty',
                                  ),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      item['qty'] = int.tryParse(v) ?? 1;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: '${item['price']}',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Unit Price ($currency)',
                                  ),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      item['price'] =
                                          double.tryParse(v) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$currency${NumberFormat("#,##0").format(itemTotal)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (lineItems.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 18, color: AppTheme.danger),
                                  onPressed: () {
                                    setDialogState(() {
                                      lineItems.removeAt(i);
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: taxPercentController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Tax Rate (%)',
                                suffixText: '%',
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: discountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Discount ($currency)',
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subtotal & Grand Total Summary Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:'),
                                Text(
                                    '$currency${NumberFormat("#,##0.00").format(subtotal)}'),
                              ],
                            ),
                            if (taxPct > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tax ($taxPct%):'),
                                  Text(
                                      '+$currency${NumberFormat("#,##0.00").format(taxAmount)}'),
                                ],
                              ),
                            ],
                            if (discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Discount:'),
                                  Text(
                                      '-$currency${NumberFormat("#,##0.00").format(discount)}'),
                                ],
                              ),
                            ],
                            const Divider(color: AppTheme.primary, height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Final Total Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  '$currency${NumberFormat("#,##0.00").format(finalTotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Payment Terms / Notes',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final items = lineItems.map((item) {
                      return QuotationLineItem(
                        description: item['desc'],
                        quantity: item['qty'],
                        unitPrice: item['price'],
                      );
                    }).toList();

                    final newQuote = Quotation(
                      id: '',
                      quoteNumber: quoteNum,
                      agencyId: agency!.id,
                      title: titleController.text.trim(),
                      clientName: clientNameController.text.trim(),
                      clientEmail: clientEmailController.text.trim(),
                      items: items,
                      subtotal: subtotal,
                      taxPercent: taxPct,
                      taxAmount: taxAmount,
                      discountAmount: discount,
                      finalTotal: finalTotal,
                      validityDate: validity,
                      notes: notesController.text.trim(),
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    crm.addQuotation(newQuote);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Quotation'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return AppTheme.success;
      case 'Sent':
        return AppTheme.info;
      case 'Rejected':
        return AppTheme.danger;
      case 'Expired':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }
}
