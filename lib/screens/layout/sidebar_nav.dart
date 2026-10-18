import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

enum NavPage {
  dashboard,
  leads,
  pipeline,
  contacts,
  companies,
  tasks,
  activities,
  quotations,
  reports,
  team,
  settings,
}

class SidebarNav extends StatelessWidget {
  final NavPage selectedPage;
  final ValueChanged<NavPage> onPageSelected;

  const SidebarNav({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final crm = context.watch<CrmProvider>();
    final agency = auth.currentAgency;
    final user = auth.user;
    final member = auth.currentMember;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate 900
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header / Agency Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hub_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        agency?.name.isNotEmpty == true
                            ? agency!.name
                            : 'ClientFlow',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            member?.role.toUpperCase() ?? 'MEMBER',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Scrollable Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _buildNavItem(
                  page: NavPage.dashboard,
                  title: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                ),
                _buildNavItem(
                  page: NavPage.leads,
                  title: 'Leads',
                  icon: Icons.person_search_outlined,
                  activeIcon: Icons.person_search,
                  badgeCount: crm.totalLeads > 0 ? crm.totalLeads : null,
                ),
                _buildNavItem(
                  page: NavPage.pipeline,
                  title: 'Sales Pipeline',
                  icon: Icons.view_kanban_outlined,
                  activeIcon: Icons.view_kanban,
                  badgeCount: crm.activeDeals > 0 ? crm.activeDeals : null,
                ),
                _buildNavItem(
                  page: NavPage.contacts,
                  title: 'Contacts',
                  icon: Icons.contacts_outlined,
                  activeIcon: Icons.contacts,
                ),
                _buildNavItem(
                  page: NavPage.companies,
                  title: 'Companies',
                  icon: Icons.domain_outlined,
                  activeIcon: Icons.domain,
                ),
                _buildNavItem(
                  page: NavPage.tasks,
                  title: 'Tasks & Follow-ups',
                  icon: Icons.check_circle_outline,
                  activeIcon: Icons.check_circle,
                  badgeCount:
                      crm.overdueFollowUps > 0 ? crm.overdueFollowUps : null,
                  badgeColor: AppTheme.danger,
                ),
                _buildNavItem(
                  page: NavPage.activities,
                  title: 'Activities',
                  icon: Icons.timeline_outlined,
                  activeIcon: Icons.timeline,
                ),
                _buildNavItem(
                  page: NavPage.quotations,
                  title: 'Quotations',
                  icon: Icons.request_quote_outlined,
                  activeIcon: Icons.request_quote,
                ),
                _buildNavItem(
                  page: NavPage.reports,
                  title: 'Reports',
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF1E293B), height: 1),
                const SizedBox(height: 12),
                _buildNavItem(
                  page: NavPage.team,
                  title: 'Team Members',
                  icon: Icons.groups_outlined,
                  activeIcon: Icons.groups,
                ),
                _buildNavItem(
                  page: NavPage.settings,
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF1E293B), height: 1),

          // Footer / User Profile & Sign Out
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  backgroundImage: user?.photoURL != null &&
                          user!.photoURL!.isNotEmpty
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user?.photoURL == null || user!.photoURL!.isEmpty
                      ? Text(
                          (user?.displayName ?? user?.email ?? 'U')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.displayName ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () => auth.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required NavPage page,
    required String title,
    required IconData icon,
    required IconData activeIcon,
    int? badgeCount,
    Color? badgeColor,
  }) {
    final isSelected = selectedPage == page;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onPageSelected(page),
          hoverColor: const Color(0xFF1E293B),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF94A3B8), // Slate 400
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFCBD5E1), // Slate 300
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (badgeColor ?? const Color(0xFF334155)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
