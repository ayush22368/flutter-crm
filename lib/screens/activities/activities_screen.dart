import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  String _selectedType = 'All';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();

    final filteredActivities = crm.activities.where((a) {
      if (_selectedType != 'All' && a.type != _selectedType) return false;
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
                      'Activity History & Timeline',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete chronological audit trail of all customer interactions and stage movements.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Log Interaction'),
                  onPressed: () => _showAddActivityDialog(context),
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
                      value: _selectedType,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...ActivityItem.types]
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('Filter Type: $t'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Timeline List
            Expanded(
              child: filteredActivities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history_edu_outlined,
                              size: 48, color: AppTheme.textLight),
                          const SizedBox(height: 12),
                          const Text(
                            'No activities found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Log your first phone call, meeting note, or customer interaction.',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Log Interaction'),
                            onPressed: () => _showAddActivityDialog(context),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        itemCount: filteredActivities.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: AppTheme.borderLight, height: 1),
                        itemBuilder: (context, index) {
                          final act = filteredActivities[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _typeColor(act.type)
                                      .withValues(alpha: 0.15),
                                  child: Icon(
                                    _typeIcon(act.type),
                                    size: 18,
                                    color: _typeColor(act.type),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            act.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppTheme.textMain,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _typeColor(act.type)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              act.type,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: _typeColor(act.type),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (act.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          act.description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            _dateFormat.format(act.createdAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textLight,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• by ${act.createdByName}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                          if (act.linkedEntityTitle
                                              .isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '• Linked: ${act.linkedEntityTitle}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
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

  void _showAddActivityDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'Call';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log Interaction / Activity'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['Call', 'Meeting', 'Email', 'Note']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedType = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title / Subject *',
                      hintText: 'e.g. Discovery call with CEO',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details / Minutes of Meeting',
                      hintText:
                          'Discussed MVP requirements, timeline: 8 weeks, budget: \$25,000...',
                    ),
                  ),
                ],
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
                  final newAct = ActivityItem(
                    id: '',
                    agencyId: auth.currentAgency!.id,
                    type: selectedType,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    createdByUid: auth.user!.uid,
                    createdByName: auth.user!.displayName ?? 'User',
                    createdAt: DateTime.now(),
                  );
                  crm.addActivity(newAct);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Activity'),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'Call':
        return Icons.phone;
      case 'Meeting':
        return Icons.groups;
      case 'Email':
        return Icons.email;
      case 'Stage Change':
        return Icons.alt_route;
      case 'System':
        return Icons.settings;
      default:
        return Icons.notes;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'Call':
        return AppTheme.primary;
      case 'Meeting':
        return AppTheme.purple;
      case 'Email':
        return AppTheme.secondary;
      case 'Stage Change':
        return AppTheme.warning;
      case 'System':
        return AppTheme.textMuted;
      default:
        return AppTheme.success;
    }
  }
}
