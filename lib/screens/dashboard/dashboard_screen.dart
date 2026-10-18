import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';
import '../layout/sidebar_nav.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<NavPage> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final crm = context.watch<CrmProvider>();
    final agency = auth.currentAgency;
    final currency = agency?.currencySymbol ?? '\$';
    final isDesktop = AppTheme.isDesktop(context);

    if (crm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${auth.user?.displayName?.split(" ").first ?? "there"} 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your agency sales and customer activity overview.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Add Lead'),
                      onPressed: () => onNavigate(NavPage.leads),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('New Deal'),
                      onPressed: () => onNavigate(NavPage.pipeline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Overdue Banner if overdue tasks exist
            if (crm.overdueFollowUps > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.danger,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Attention: You have ${crm.overdueFollowUps} overdue follow-up task${crm.overdueFollowUps > 1 ? "s" : ""} requiring immediate action.',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onNavigate(NavPage.tasks),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                      ),
                      child: const Text('View Overdue Tasks →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Row 1: Key Metrics Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1100
                    ? 4
                    : constraints.maxWidth >= 600
                        ? 2
                        : 1;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth >= 1100 ? 1.7 : 2.0,
                  children: [
                    _buildMetricCard(
                      title: 'Total Leads',
                      value: '${crm.totalLeads}',
                      subtext: '+${crm.newLeadsThisMonth} new this month',
                      icon: Icons.person_search,
                      iconColor: AppTheme.info,
                      onTap: () => onNavigate(NavPage.leads),
                    ),
                    _buildMetricCard(
                      title: 'Active Deals',
                      value: '${crm.activeDeals}',
                      subtext:
                          'Open pipeline: $currency${NumberFormat.compact().format(crm.openPipelineValue)}',
                      icon: Icons.view_kanban,
                      iconColor: AppTheme.purple,
                      onTap: () => onNavigate(NavPage.pipeline),
                    ),
                    _buildMetricCard(
                      title: 'Won Deals This Month',
                      value: '${crm.wonDealsThisMonth}',
                      subtext:
                          'Total Won: $currency${NumberFormat.compact().format(crm.wonDealsValue)}',
                      icon: Icons.verified,
                      iconColor: AppTheme.success,
                      onTap: () => onNavigate(NavPage.pipeline),
                    ),
                    _buildMetricCard(
                      title: 'Follow-ups Due Today',
                      value: '${crm.followUpsDueToday}',
                      subtext: '${crm.overdueFollowUps} overdue follow-ups',
                      subtextColor: crm.overdueFollowUps > 0
                          ? AppTheme.danger
                          : AppTheme.textMuted,
                      icon: Icons.access_time_filled,
                      iconColor: AppTheme.warning,
                      onTap: () => onNavigate(NavPage.tasks),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Row 2: Charts & Visual Analytics
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sales Pipeline Bar Chart
                  Expanded(
                    flex: 7,
                    child: _buildPipelineDistributionCard(crm, currency),
                  ),
                  const SizedBox(width: 20),
                  // Lead Sources Breakdown Pie Chart
                  Expanded(
                    flex: 5,
                    child: _buildLeadSourcesCard(crm),
                  ),
                ],
              )
            else ...[
              _buildPipelineDistributionCard(crm, currency),
              const SizedBox(height: 20),
              _buildLeadSourcesCard(crm),
            ],

            const SizedBox(height: 24),

            // Row 3: Follow-ups Today + Recent Activities
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildTodayFollowUpsCard(crm, onNavigate),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: _buildRecentActivitiesCard(crm, onNavigate),
                  ),
                ],
              )
            else ...[
              _buildTodayFollowUpsCard(crm, onNavigate),
              const SizedBox(height: 20),
              _buildRecentActivitiesCard(crm, onNavigate),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    Color? subtextColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: subtextColor ?? AppTheme.textMuted,
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

  static Widget _buildPipelineDistributionCard(
      CrmProvider crm, String currency) {
    final stages = [
      'New Lead',
      'Contacted',
      'Qualified',
      'Proposal Sent',
      'Negotiation',
      'Won',
      'Lost'
    ];
    final values = crm.dealsValueByStage;
    final maxVal = values.values.fold(0.0, (m, v) => v > m ? v : m);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales Pipeline Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                Text(
                  'Total Open: $currency${NumberFormat.compact().format(crm.openPipelineValue)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Value of deals currently residing in each pipeline phase',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            if (crm.deals.isEmpty)
              _buildEmptyState(
                icon: Icons.view_kanban_outlined,
                message: 'No deals added to the pipeline yet.',
              )
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal > 0 ? maxVal * 1.2 : 1000,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${stages[group.x.toInt()]}\n$currency${NumberFormat.compact().format(rod.toY)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (val, meta) => Text(
                            '$currency${NumberFormat.compact().format(val)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= stages.length) {
                              return const SizedBox.shrink();
                            }
                            final shortNames = [
                              'New',
                              'Cont.',
                              'Qual.',
                              'Prop.',
                              'Neg.',
                              'Won',
                              'Lost'
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                shortNames[idx],
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxVal > 0 ? maxVal / 4 : 250,
                      getDrawingHorizontalLine: (val) => const FlLine(
                        color: AppTheme.borderLight,
                        strokeWidth: 0.8,
                      ),
                    ),
                    barGroups: List.generate(stages.length, (index) {
                      final stage = stages[index];
                      final val = values[stage] ?? 0.0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            color: AppTheme.getStageColor(stage),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildLeadSourcesCard(CrmProvider crm) {
    final sources = crm.leadsBySource;
    final total = sources.values.fold(0, (sum, count) => sum + count);

    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.purple,
      AppTheme.warning,
      AppTheme.success,
      const Color(0xFF64748B),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lead Sources Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Where your potential customers are coming from',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            if (total == 0)
              _buildEmptyState(
                icon: Icons.pie_chart_outline,
                message: 'No leads registered yet.',
              )
            else
              Row(
                children: [
                  SizedBox(
                    height: 170,
                    width: 170,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(sources.keys.length, (index) {
                          final key = sources.keys.elementAt(index);
                          final count = sources[key] ?? 0;
                          final pct = total > 0 ? (count / total) * 100 : 0.0;
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: count.toDouble(),
                            title: count > 0 ? '${pct.toStringAsFixed(0)}%' : '',
                            radius: 35,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(sources.keys.length, (index) {
                        final key = sources.keys.elementAt(index);
                        final count = sources[key] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ),
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTodayFollowUpsCard(
      CrmProvider crm, ValueChanged<NavPage> onNavigate) {
    final todayTasks = crm.tasks.where((t) => t.isDueToday).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Follow-ups & Tasks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(NavPage.tasks),
                  child: const Text('All Tasks →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (todayTasks.isEmpty)
              _buildEmptyState(
                icon: Icons.check_circle_outline,
                message: 'No follow-up tasks scheduled for today. Great job!',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayTasks.take(5).length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppTheme.borderLight, height: 1),
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (val) {
                        crm.toggleTaskCompleted(task, val ?? false);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      '${task.type} • Assigned: ${task.assignedToName.isNotEmpty ? task.assignedToName : "Unassigned"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getPriorityColor(task.priority)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getPriorityColor(task.priority),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildRecentActivitiesCard(
      CrmProvider crm, ValueChanged<NavPage> onNavigate) {
    final activities = crm.recentActivities;
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent CRM Activities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                TextButton(
                  onPressed: () => onNavigate(NavPage.activities),
                  child: const Text('View All →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              _buildEmptyState(
                icon: Icons.history,
                message: 'No activities recorded yet.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.take(5).length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppTheme.borderLight, height: 1),
                itemBuilder: (context, index) {
                  final act = activities[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryLight,
                          child: Icon(
                            _activityIcon(act.type),
                            size: 14,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              if (act.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  act.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${dateFormat.format(act.createdAt)} • by ${act.createdByName}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.textLight),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _activityIcon(String type) {
    switch (type) {
      case 'Call':
        return Icons.phone;
      case 'Meeting':
        return Icons.groups;
      case 'Email':
        return Icons.email;
      case 'Stage Change':
        return Icons.alt_route;
      default:
        return Icons.notes;
    }
  }
}
