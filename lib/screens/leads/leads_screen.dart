import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/lead_model.dart';
import '../../models/deal_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _sourceFilter = 'All';
  String _serviceFilter = 'All';
  String _sortBy = 'Newest';
  bool _showArchived = false;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();
    final currency = auth.currentAgency?.currencySymbol ?? '\$';

    // Filter & Sort
    var filteredLeads = crm.leads.where((lead) {
      if (!_showArchived && lead.isArchived) return false;
      if (_showArchived && !lead.isArchived) return false;

      if (_statusFilter != 'All' && lead.status != _statusFilter) return false;
      if (_sourceFilter != 'All' && lead.source != _sourceFilter) return false;
      if (_serviceFilter != 'All' && lead.interestedService != _serviceFilter) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = lead.fullName.toLowerCase().contains(q);
        final matchesEmail = lead.email.toLowerCase().contains(q);
        final matchesPhone = lead.phone.toLowerCase().contains(q);
        final matchesCompany = lead.companyName.toLowerCase().contains(q);
        if (!matchesName && !matchesEmail && !matchesPhone && !matchesCompany) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort
    if (_sortBy == 'Newest') {
      filteredLeads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Oldest') {
      filteredLeads.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'Name') {
      filteredLeads.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (_sortBy == 'Budget High-Low') {
      filteredLeads.sort((a, b) => b.estimatedBudget.compareTo(a.estimatedBudget));
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leads Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Capture, qualify, and convert prospective software development clients.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New Lead'),
                  onPressed: () => _showAddEditLeadDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search field
                    SizedBox(
                      width: 260,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search by name, email, company...',
                          prefixIcon: Icon(Icons.search, size: 18),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                      ),
                    ),

                    // Status Dropdown
                    DropdownButton<String>(
                      value: _statusFilter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...Lead.statuses]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Status: $s'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _statusFilter = val);
                      },
                    ),

                    // Source Dropdown
                    DropdownButton<String>(
                      value: _sourceFilter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...Lead.sources]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Source: $s'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sourceFilter = val);
                      },
                    ),

                    // Service Dropdown
                    DropdownButton<String>(
                      value: _serviceFilter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...Lead.services]
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Service: $s'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _serviceFilter = val);
                      },
                    ),

                    // Sort
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox.shrink(),
                      items: ['Newest', 'Oldest', 'Name', 'Budget High-Low']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text('Sort: $s'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),

                    // Archive Toggle
                    FilterChip(
                      selected: _showArchived,
                      label: const Text('Archived'),
                      onSelected: (val) {
                        setState(() => _showArchived = val);
                      },
                    ),

                    // Clear Filters
                    if (_searchQuery.isNotEmpty ||
                        _statusFilter != 'All' ||
                        _sourceFilter != 'All' ||
                        _serviceFilter != 'All' ||
                        _showArchived)
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Reset'),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _statusFilter = 'All';
                            _sourceFilter = 'All';
                            _serviceFilter = 'All';
                            _showArchived = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Leads Data List / Table
            Expanded(
              child: filteredLeads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_search_outlined,
                            size: 48,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No leads found matching your criteria',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try clearing active filters or add a new prospective lead.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Create Lead'),
                            onPressed: () => _showAddEditLeadDialog(context),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      child: ListView.separated(
                        itemCount: filteredLeads.length,
                        separatorBuilder: (_, __) => const Divider(
                          color: AppTheme.borderLight,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final lead = filteredLeads[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.getLeadStatusColor(lead.status)
                                      .withValues(alpha: 0.15),
                              child: Text(
                                lead.fullName.isNotEmpty
                                    ? lead.fullName[0].toUpperCase()
                                    : 'L',
                                style: TextStyle(
                                  color: AppTheme.getLeadStatusColor(lead.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  lead.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                if (lead.companyName.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgLight,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: AppTheme.borderLight),
                                    ),
                                    child: Text(
                                      lead.companyName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 14,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 13, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        lead.email,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  if (lead.phone.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 13, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(
                                          lead.phone,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  Text(
                                    '• ${lead.interestedService}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '• Source: ${lead.source}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                  if (lead.nextFollowUpDate != null)
                                    Text(
                                      '• Next Follow-up: ${_dateFormat.format(lead.nextFollowUpDate!)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Budget Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgLight,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: AppTheme.borderLight),
                                  ),
                                  child: Text(
                                    '$currency${NumberFormat.compact().format(lead.estimatedBudget)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.getLeadStatusColor(
                                            lead.status)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    lead.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.getLeadStatusColor(
                                          lead.status),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Actions Menu
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 20),
                                  onSelected: (action) {
                                    if (action == 'view') {
                                      _showLeadDetailsDialog(context, lead);
                                    } else if (action == 'edit') {
                                      _showAddEditLeadDialog(context, lead: lead);
                                    } else if (action == 'convert') {
                                      _convertLeadToDeal(context, lead);
                                    } else if (action == 'archive') {
                                      crm.archiveLead(lead, !lead.isArchived);
                                    } else if (action == 'delete') {
                                      _confirmDeleteLead(context, lead);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility, size: 16),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 16),
                                          SizedBox(width: 8),
                                          Text('Edit Lead'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'convert',
                                      child: Row(
                                        children: [
                                          Icon(Icons.transform,
                                              size: 16,
                                              color: AppTheme.primary),
                                          SizedBox(width: 8),
                                          Text('Convert to Deal'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: Row(
                                        children: [
                                          Icon(
                                              lead.isArchived
                                                  ? Icons.unarchive
                                                  : Icons.archive,
                                              size: 16),
                                          const SizedBox(width: 8),
                                          Text(lead.isArchived
                                              ? 'Unarchive'
                                              : 'Archive'),
                                        ],
                                      ),
                                    ),
                                    if (auth.isAdmin)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                size: 16,
                                                color: AppTheme.danger),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: AppTheme.danger)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => _showLeadDetailsDialog(context, lead),
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
  // ADD / EDIT LEAD DIALOG (With Duplicate Check Warning)
  // ----------------------------------------------------

  void _showAddEditLeadDialog(BuildContext context, {Lead? lead}) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final nameController = TextEditingController(text: lead?.fullName ?? '');
    final companyController =
        TextEditingController(text: lead?.companyName ?? '');
    final emailController = TextEditingController(text: lead?.email ?? '');
    final phoneController = TextEditingController(text: lead?.phone ?? '');
    final budgetController = TextEditingController(
      text: lead != null ? lead.estimatedBudget.toString() : '5000',
    );
    final notesController = TextEditingController(text: lead?.notes ?? '');

    String selectedService = lead?.interestedService ?? 'Web Development';
    String selectedSource = lead?.source ?? 'Website';
    String selectedStatus = lead?.status ?? 'New';
    String selectedAssignedUid = lead?.assignedToUid ?? auth.user?.uid ?? '';
    DateTime? nextFollowUp =
        lead?.nextFollowUpDate ?? DateTime.now().add(const Duration(days: 3));

    List<String> duplicateWarnings = [];
    bool isCheckingDuplicate = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(lead == null ? 'Add New Lead' : 'Edit Lead'),
              content: SizedBox(
                width: 580,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Duplicate Warning Banner
                        if (duplicateWarnings.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.warning),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning,
                                        color: AppTheme.warning, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Possible Duplicate Lead Detected!',
                                      style: TextStyle(
                                        color: AppTheme.warning,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...duplicateWarnings.map(
                                  (w) => Text('• $w',
                                      style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter full name'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address *',
                                  prefixIcon: Icon(Icons.email),
                                ),
                                validator: (v) => v == null || !v.contains('@')
                                    ? 'Enter valid email'
                                    : null,
                                onChanged: (v) async {
                                  if (v.contains('@')) {
                                    final dupes =
                                        await crm.checkLeadDuplicates(
                                      email: v,
                                      phone: phoneController.text,
                                      excludeLeadId: lead?.id,
                                    );
                                    setDialogState(
                                        () => duplicateWarnings = dupes);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                onChanged: (v) async {
                                  if (v.trim().length >= 7) {
                                    final dupes =
                                        await crm.checkLeadDuplicates(
                                      email: emailController.text,
                                      phone: v,
                                      excludeLeadId: lead?.id,
                                    );
                                    setDialogState(
                                        () => duplicateWarnings = dupes);
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
                                  labelText: 'Company / Business Name',
                                  prefixIcon: Icon(Icons.domain),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: budgetController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Estimated Budget',
                                  prefixText:
                                      '${auth.currentAgency?.currencySymbol ?? "\$"} ',
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
                                  labelText: 'Interested Service',
                                ),
                                items: Lead.services
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
                                value: selectedSource,
                                decoration: const InputDecoration(
                                  labelText: 'Lead Source',
                                ),
                                items: Lead.sources
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => selectedSource = v);
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
                              child: DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                items: Lead.statuses
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => selectedStatus = v);
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
                                  labelText: 'Assign To',
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

                        // Next follow up date picker
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Next Follow-up Date'),
                          subtitle: Text(
                            nextFollowUp != null
                                ? _dateFormat.format(nextFollowUp!)
                                : 'No follow-up scheduled',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 20),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: nextFollowUp ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => nextFollowUp = picked);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes / Project Requirements',
                            hintText: 'Client needs modern mobile app with...',
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
                      final assignedMember = crm.members.firstWhere(
                        (m) => m.uid == selectedAssignedUid,
                        orElse: () => crm.members.isNotEmpty
                            ? crm.members.first
                            : crm.members.first,
                      );

                      final budget =
                          double.tryParse(budgetController.text) ?? 0.0;

                      if (lead == null) {
                        final newLead = Lead(
                          id: '',
                          agencyId: auth.currentAgency!.id,
                          fullName: nameController.text.trim(),
                          companyName: companyController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          interestedService: selectedService,
                          estimatedBudget: budget,
                          source: selectedSource,
                          status: selectedStatus,
                          assignedToUid: selectedAssignedUid,
                          assignedToName: selectedAssignedUid.isNotEmpty
                              ? assignedMember.displayName
                              : '',
                          notes: notesController.text.trim(),
                          nextFollowUpDate: nextFollowUp,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await crm.addLead(newLead);
                      } else {
                        final updated = lead.copyWith(
                          fullName: nameController.text.trim(),
                          companyName: companyController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          interestedService: selectedService,
                          estimatedBudget: budget,
                          source: selectedSource,
                          status: selectedStatus,
                          assignedToUid: selectedAssignedUid,
                          assignedToName: selectedAssignedUid.isNotEmpty
                              ? assignedMember.displayName
                              : '',
                          notes: notesController.text.trim(),
                          nextFollowUpDate: nextFollowUp,
                          updatedAt: DateTime.now(),
                        );
                        await crm.updateLead(updated);
                      }
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: Text(lead == null ? 'Save Lead' : 'Update Lead'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // LEAD DETAILS MODAL
  // ----------------------------------------------------

  void _showLeadDetailsDialog(BuildContext context, Lead lead) {
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
              Text(lead.fullName),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.getLeadStatusColor(lead.status)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lead.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getLeadStatusColor(lead.status),
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Company:', lead.companyName.isNotEmpty ? lead.companyName : 'None'),
                  _detailRow('Email:', lead.email),
                  _detailRow('Phone:', lead.phone.isNotEmpty ? lead.phone : 'Not provided'),
                  _detailRow('Service of Interest:', lead.interestedService),
                  _detailRow('Estimated Budget:', '$currency${lead.estimatedBudget.toStringAsFixed(2)}'),
                  _detailRow('Lead Source:', lead.source),
                  _detailRow('Assigned To:', lead.assignedToName.isNotEmpty ? lead.assignedToName : 'Unassigned'),
                  _detailRow('Next Follow-up:', lead.nextFollowUpDate != null ? _dateFormat.format(lead.nextFollowUpDate!) : 'None scheduled'),
                  _detailRow('Created Date:', _dateFormat.format(lead.createdAt)),
                  const SizedBox(height: 14),
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Text(
                      lead.notes.isNotEmpty ? lead.notes : 'No notes recorded for this lead.',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
              onPressed: () {
                Navigator.pop(ctx);
                _showAddEditLeadDialog(context, lead: lead);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.transform, size: 16),
              label: const Text('Convert to Deal'),
              onPressed: () {
                Navigator.pop(ctx);
                _convertLeadToDeal(context, lead);
              },
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // CONVERT LEAD TO DEAL
  // ----------------------------------------------------

  void _convertLeadToDeal(BuildContext context, Lead lead) {
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final deal = Deal(
      id: '',
      agencyId: auth.currentAgency!.id,
      title: '${lead.companyName.isNotEmpty ? lead.companyName : lead.fullName} - ${lead.interestedService}',
      dealValue: lead.estimatedBudget,
      expectedCloseDate: DateTime.now().add(const Duration(days: 30)),
      stage: 'New Lead',
      assignedToUid: lead.assignedToUid,
      assignedToName: lead.assignedToName,
      serviceOffered: lead.interestedService,
      associatedLeadId: lead.id,
      companyName: lead.companyName,
      contactName: lead.fullName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    crm.addDeal(deal);
    crm.updateLead(lead.copyWith(status: 'Qualified'));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lead converted to Deal "${deal.title}" in Sales Pipeline!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _confirmDeleteLead(BuildContext context, Lead lead) {
    final crm = context.read<CrmProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: Text('Are you sure you want to permanently delete lead "${lead.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              crm.deleteLead(lead.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textMuted),
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
