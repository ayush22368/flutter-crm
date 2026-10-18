import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/deal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  String _employeeFilter = 'All';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();
    final currency = auth.currentAgency?.currencySymbol ?? '\$';

    // Filter deals
    final filteredDeals = crm.deals.where((d) {
      if (_employeeFilter != 'All' && d.assignedToUid != _employeeFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Top Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Pipeline & Deals',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track deal progress through stages from New Lead to Won.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Filter by Employee
                    DropdownButton<String>(
                      value: _employeeFilter,
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All Team Members'),
                        ),
                        ...crm.members.map((m) => DropdownMenuItem(
                              value: m.uid,
                              child: Text(m.displayName),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _employeeFilter = val);
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Deal'),
                      onPressed: () => _showAddEditDealDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Kanban Horizontal Scroll Area
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: Deal.stages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final stage = Deal.stages[index];
                final stageDeals =
                    filteredDeals.where((d) => d.stage == stage).toList();
                final totalStageValue = stageDeals.fold(
                    0.0, (sum, item) => sum + item.dealValue);

                return _buildKanbanColumn(
                  context: context,
                  stage: stage,
                  deals: stageDeals,
                  totalValue: totalStageValue,
                  currency: currency,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // KANBAN COLUMN
  // ----------------------------------------------------

  Widget _buildKanbanColumn({
    required BuildContext context,
    required String stage,
    required List<Deal> deals,
    required double totalValue,
    required String currency,
  }) {
    final stageColor = AppTheme.getStageColor(stage);
    final crm = context.read<CrmProvider>();

    return DragTarget<Deal>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) {
        _handleDealStageDrop(context, details.data, stage);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Container(
          width: 310,
          decoration: BoxDecoration(
            color: isHovered
                ? stageColor.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9), // Slate 100
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovered ? stageColor : AppTheme.borderLight,
              width: isHovered ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: stageColor, width: 4),
                    bottom: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stage,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: stageColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${deals.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stageColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $currency${NumberFormat.compact().format(totalValue)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Deals List in Column
              Expanded(
                child: deals.isEmpty
                    ? Center(
                        child: Text(
                          'No deals in $stage',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: deals.length,
                        itemBuilder: (context, idx) {
                          final deal = deals[idx];
                          return Draggable<Deal>(
                            data: deal,
                            feedback: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 290,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: stageColor),
                                ),
                                child: Text(
                                  deal.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _buildDealCard(context, deal, currency),
                            ),
                            child: _buildDealCard(context, deal, currency),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // DEAL CARD
  // ----------------------------------------------------

  Widget _buildDealCard(BuildContext context, Deal deal, String currency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDealDetailsDialog(context, deal),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              if (deal.companyName.isNotEmpty || deal.contactName.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        deal.companyName.isNotEmpty
                            ? deal.companyName
                            : deal.contactName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$currency${NumberFormat("#,##0").format(deal.dealValue)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      deal.serviceOffered,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 4),
                      Text(
                        _dateFormat.format(deal.expectedCloseDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  if (deal.assignedToName.isNotEmpty)
                    Text(
                      deal.assignedToName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // HANDLE STAGE CHANGE / DROP (Prompt reason if Lost)
  // ----------------------------------------------------

  void _handleDealStageDrop(
    BuildContext context,
    Deal deal,
    String targetStage,
  ) {
    final crm = context.read<CrmProvider>();

    if (targetStage == 'Lost') {
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mark Deal as Lost'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please specify the reason this deal was lost for agency reporting:',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Lost Reason *',
                  hintText: 'e.g. Budget too low, Competitor chosen, Project postponed',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              onPressed: () {
                final reason = reasonController.text.trim();
                crm.changeDealStage(
                  deal,
                  'Lost',
                  lostReason: reason.isNotEmpty ? reason : 'No reason provided',
                );
                Navigator.pop(ctx);
              },
              child: const Text('Confirm Lost'),
            ),
          ],
        ),
      );
    } else {
      crm.changeDealStage(deal, targetStage);
    }
  }

  // ----------------------------------------------------
  // ADD / EDIT DEAL DIALOG
  // ----------------------------------------------------

  void _showAddEditDealDialog(BuildContext context, {Deal? deal}) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final titleController = TextEditingController(text: deal?.title ?? '');
    final valueController = TextEditingController(
      text: deal != null ? deal.dealValue.toString() : '10000',
    );
    final companyController =
        TextEditingController(text: deal?.companyName ?? '');
    final contactController =
        TextEditingController(text: deal?.contactName ?? '');

    String selectedStage = deal?.stage ?? 'New Lead';
    String selectedService = deal?.serviceOffered ?? 'Web Development';
    String selectedAssignedUid = deal?.assignedToUid ?? auth.user?.uid ?? '';
    DateTime expectedDate = deal?.expectedCloseDate ??
        DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(deal == null ? 'Add Deal' : 'Edit Deal'),
              content: SizedBox(
                width: 540,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Deal Title *',
                            hintText: 'e.g. FinTech Mobile App Platform',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter title'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: valueController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Deal Value *',
                                  prefixText:
                                      '${auth.currentAgency?.currencySymbol ?? "\$"} ',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter value'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedStage,
                                decoration: const InputDecoration(
                                  labelText: 'Pipeline Stage',
                                ),
                                items: Deal.stages
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => selectedStage = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: companyController,
                                decoration: const InputDecoration(
                                  labelText: 'Company / Client',
                                  prefixIcon: Icon(Icons.domain),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: contactController,
                                decoration: const InputDecoration(
                                  labelText: 'Primary Contact Person',
                                  prefixIcon: Icon(Icons.person),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedService,
                                decoration: const InputDecoration(
                                  labelText: 'Service Offered',
                                ),
                                items: const [
                                  'Web Development',
                                  'Mobile Application',
                                  'Custom Software',
                                  'UI/UX Design',
                                  'Maintenance & Support',
                                  'Cloud & DevOps',
                                  'Other',
                                ]
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => selectedService = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: crm.members.any(
                                        (m) => m.uid == selectedAssignedUid)
                                    ? selectedAssignedUid
                                    : (crm.members.isNotEmpty
                                        ? crm.members.first.uid
                                        : ''),
                                decoration: const InputDecoration(
                                  labelText: 'Assigned To',
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('Unassigned'),
                                  ),
                                  ...crm.members.map((m) => DropdownMenuItem(
                                        value: m.uid,
                                        child: Text(m.displayName),
                                      )),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(
                                        () => selectedAssignedUid = v);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expected Closing Date'),
                          subtitle: Text(_dateFormat.format(expectedDate)),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: expectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 730)),
                              );
                              if (picked != null) {
                                setDialogState(() => expectedDate = picked);
                              }
                            },
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
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final assigned = crm.members.firstWhere(
                        (m) => m.uid == selectedAssignedUid,
                        orElse: () => crm.members.isNotEmpty
                            ? crm.members.first
                            : crm.members.first,
                      );
                      final val = double.tryParse(valueController.text) ?? 0.0;

                      if (deal == null) {
                        final newDeal = Deal(
                          id: '',
                          agencyId: auth.currentAgency!.id,
                          title: titleController.text.trim(),
                          dealValue: val,
                          expectedCloseDate: expectedDate,
                          stage: selectedStage,
                          assignedToUid: selectedAssignedUid,
                          assignedToName: selectedAssignedUid.isNotEmpty
                              ? assigned.displayName
                              : '',
                          serviceOffered: selectedService,
                          companyName: companyController.text.trim(),
                          contactName: contactController.text.trim(),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await crm.addDeal(newDeal);
                      } else {
                        final updated = deal.copyWith(
                          title: titleController.text.trim(),
                          dealValue: val,
                          expectedCloseDate: expectedDate,
                          stage: selectedStage,
                          assignedToUid: selectedAssignedUid,
                          assignedToName: selectedAssignedUid.isNotEmpty
                              ? assigned.displayName
                              : '',
                          serviceOffered: selectedService,
                          companyName: companyController.text.trim(),
                          contactName: contactController.text.trim(),
                          updatedAt: DateTime.now(),
                        );
                        await crm.updateDeal(updated);
                      }
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(deal == null ? 'Create Deal' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // DEAL DETAILS DIALOG WITH STAGE HISTORY
  // ----------------------------------------------------

  void _showDealDetailsDialog(BuildContext context, Deal deal) {
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();
    final currency = auth.currentAgency?.currencySymbol ?? '\$';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  deal.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.getStageColor(deal.stage)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deal.stage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getStageColor(deal.stage),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Deal Value:',
                      '$currency${NumberFormat("#,##0.00").format(deal.dealValue)}'),
                  _detailRow('Service Offered:', deal.serviceOffered),
                  _detailRow('Company:',
                      deal.companyName.isNotEmpty ? deal.companyName : 'None'),
                  _detailRow('Contact Person:',
                      deal.contactName.isNotEmpty ? deal.contactName : 'None'),
                  _detailRow('Assigned To:',
                      deal.assignedToName.isNotEmpty ? deal.assignedToName : 'Unassigned'),
                  _detailRow('Expected Closing:',
                      _dateFormat.format(deal.expectedCloseDate)),
                  if (deal.isLost && deal.lostReason.isNotEmpty)
                    _detailRow('Reason for Losing:', deal.lostReason),
                  const SizedBox(height: 16),

                  // Stage History Log
                  const Text(
                    'Stage Transition History:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (deal.stageHistory.isEmpty)
                    const Text(
                      'No stage transitions recorded yet.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: deal.stageHistory.map((h) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right_alt,
                                    size: 16, color: AppTheme.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${h.fromStage.isNotEmpty ? h.fromStage + " → " : ""}${h.toStage} • by ${h.changedByName} (${_dateFormat.format(h.timestamp)})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            if (!deal.isLost)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Mark as Lost'),
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleDealStageDrop(context, deal, 'Lost');
                },
              ),
            if (!deal.isWon)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.verified, size: 16),
                label: const Text('Mark as Won 🎉'),
                onPressed: () {
                  Navigator.pop(ctx);
                  crm.changeDealStage(deal, 'Won', note: 'Deal closed as Won');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Deal "${deal.title}" marked as WON! Revenue added to dashboard.'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                },
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(ctx);
                _showAddEditDealDialog(context, deal: deal);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            if (auth.isAdmin)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                onPressed: () {
                  crm.deleteDeal(deal.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete Deal'),
              ),
          ],
        );
      },
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
            ),
          ),
        ],
      ),
    );
  }
}
