import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _employeeFilter = 'All';
  String _typeFilter = 'All';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();

    final allTasks = crm.tasks.where((t) {
      if (_employeeFilter != 'All' && t.assignedToUid != _employeeFilter) {
        return false;
      }
      if (_typeFilter != 'All' && t.type != _typeFilter) {
        return false;
      }
      return true;
    }).toList();

    final now = DateTime.now();
    final todayTasks = allTasks.where((t) => t.isDueToday).toList();
    final overdueTasks = allTasks.where((t) => t.isOverdue).toList();
    final upcomingTasks =
        allTasks.where((t) => !t.isCompleted && t.dueDate.isAfter(now)).toList();
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();

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
                      'Tasks & Follow-ups',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Never miss a client call, proposal follow-up, or discovery meeting.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_task, size: 18),
                  label: const Text('Add Task'),
                  onPressed: () => _showAddEditTaskDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Top Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<String>(
                      value: _typeFilter,
                      underline: const SizedBox.shrink(),
                      items: ['All', ...TaskItem.types]
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('Type: $t'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _typeFilter = val);
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _employeeFilter,
                      underline: const SizedBox.shrink(),
                      items: [
                        const DropdownMenuItem(
                            value: 'All', child: Text('All Employees')),
                        ...crm.members.map((m) => DropdownMenuItem(
                              value: m.uid,
                              child: Text(m.displayName),
                            )),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _employeeFilter = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tabs Header
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                tabs: [
                  Tab(text: 'All Tasks (${allTasks.length})'),
                  Tab(text: 'Today (${todayTasks.length})'),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Overdue'),
                        if (overdueTasks.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${overdueTasks.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(text: 'Upcoming (${upcomingTasks.length})'),
                  Tab(text: 'Completed (${completedTasks.length})'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList(allTasks, 'No tasks created yet.'),
                  _buildTaskList(todayTasks, 'No follow-up tasks due today!'),
                  _buildTaskList(overdueTasks, 'No overdue tasks. All caught up!'),
                  _buildTaskList(upcomingTasks, 'No upcoming scheduled tasks.'),
                  _buildTaskList(completedTasks, 'No completed tasks yet.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<TaskItem> tasks, String emptyMessage) {
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 48, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: ListView.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppTheme.borderLight, height: 1),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isOverdue = task.isOverdue;

          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (val) {
                crm.toggleTaskCompleted(task, val ?? false);
              },
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? AppTheme.textLight
                          : AppTheme.textMain,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getPriorityColor(task.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getPriorityColor(task.priority),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: isOverdue ? AppTheme.danger : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _dateFormat.format(task.dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                          color: isOverdue
                              ? AppTheme.danger
                              : AppTheme.textMuted,
                        ),
                      ),
                      if (isOverdue) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.danger,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text('• ${task.type}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                  if (task.linkedEntityTitle.isNotEmpty)
                    Text('• Linked: ${task.linkedEntityTitle}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary)),
                  if (task.assignedToName.isNotEmpty)
                    Text('• Assigned: ${task.assignedToName}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textLight)),
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (val) {
                if (val == 'edit') {
                  _showAddEditTaskDialog(context, task: task);
                } else if (val == 'delete') {
                  crm.deleteTask(task.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit Task'),
                    ],
                  ),
                ),
                if (auth.isAdmin)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppTheme.danger),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppTheme.danger)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddEditTaskDialog(BuildContext context, {TaskItem? task}) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController =
        TextEditingController(text: task?.description ?? '');

    String selectedType = task?.type ?? 'Phone call';
    String selectedPriority = task?.priority ?? 'Medium';
    String selectedAssignedUid = task?.assignedToUid ?? auth.user?.uid ?? '';
    DateTime selectedDueDate = task?.dueDate ??
        DateTime.now().add(const Duration(hours: 4));

    // Linked entity
    String linkedType = task?.linkedEntityType ?? 'none';
    String linkedTitle = task?.linkedEntityTitle ?? '';
    String linkedId = task?.linkedEntityId ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(task == null ? 'Schedule Task / Follow-up' : 'Edit Task'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title *',
                          hintText: 'e.g. Follow up on proposal sent',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter task title'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: const InputDecoration(
                                labelText: 'Task Type',
                              ),
                              items: TaskItem.types
                                  .map((t) => DropdownMenuItem(
                                      value: t, child: Text(t)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => selectedType = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                              ),
                              items: TaskItem.priorities
                                  .map((p) => DropdownMenuItem(
                                      value: p, child: Text(p)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => selectedPriority = v);
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
                              value: crm.members.any(
                                      (m) => m.uid == selectedAssignedUid)
                                  ? selectedAssignedUid
                                  : (crm.members.isNotEmpty
                                      ? crm.members.first.uid
                                      : ''),
                              decoration: const InputDecoration(
                                labelText: 'Assign Employee',
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: '', child: Text('Unassigned')),
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
                        title: const Text('Due Date & Time'),
                        subtitle: Text(_dateFormat.format(selectedDueDate)),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time, size: 20),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 30)),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay.fromDateTime(selectedDueDate),
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedDueDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description / Instructions',
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
                    final assigned = crm.members.firstWhere(
                      (m) => m.uid == selectedAssignedUid,
                      orElse: () => crm.members.isNotEmpty
                          ? crm.members.first
                          : crm.members.first,
                    );

                    if (task == null) {
                      final newTask = TaskItem(
                        id: '',
                        agencyId: auth.currentAgency!.id,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        type: selectedType,
                        priority: selectedPriority,
                        dueDate: selectedDueDate,
                        assignedToUid: selectedAssignedUid,
                        assignedToName: selectedAssignedUid.isNotEmpty
                            ? assigned.displayName
                            : '',
                        linkedEntityType: linkedType,
                        linkedEntityId: linkedId,
                        linkedEntityTitle: linkedTitle,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );
                      crm.addTask(newTask);
                    } else {
                      final updated = task.copyWith(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        type: selectedType,
                        priority: selectedPriority,
                        dueDate: selectedDueDate,
                        assignedToUid: selectedAssignedUid,
                        assignedToName: selectedAssignedUid.isNotEmpty
                            ? assigned.displayName
                            : '',
                        updatedAt: DateTime.now(),
                      );
                      crm.updateTask(updated);
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(task == null ? 'Schedule Task' : 'Update Task'),
              ),
            ],
          );
        },
      ),
    );
  }
}
