import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/agency_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();
    final agency = auth.currentAgency;
    final dateFormat = DateFormat('MMM dd, yyyy');

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
                      'Team Members & Workspace Access',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invite agency developers, project managers, and sales reps.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                if (auth.isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Invite Member'),
                    onPressed: () => _showInviteDialog(context, agency),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Agency Invite Code Banner
            if (agency != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.vpn_key,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agency Workspace Invite Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Share this code with your team members so they can join this workspace.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: SelectableText(
                        agency.inviteCode,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Copy Invite Code',
                      icon: const Icon(Icons.copy,
                          size: 18, color: AppTheme.primary),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: agency.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invite Code copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Team Members List
            Expanded(
              child: Card(
                child: ListView.separated(
                  itemCount: crm.members.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppTheme.borderLight, height: 1),
                  itemBuilder: (context, index) {
                    final member = crm.members[index];
                    final isCurrentUser = member.uid == auth.user?.uid;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary,
                        backgroundImage: member.photoUrl.isNotEmpty
                            ? NetworkImage(member.photoUrl)
                            : null,
                        child: member.photoUrl.isEmpty
                            ? Text(
                                member.displayName.isNotEmpty
                                    ? member.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Text(
                            member.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textMain,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.bgLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${member.email} • Joined ${dateFormat.format(member.joinedAt)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.isOwner
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : member.isAdmin
                                      ? AppTheme.purple.withValues(alpha: 0.15)
                                      : AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: member.isOwner
                                    ? AppTheme.primary
                                    : member.isAdmin
                                        ? AppTheme.purple
                                        : AppTheme.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Active / Inactive Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.isActive
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              member.isActive ? 'ACTIVE' : 'DEACTIVATED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: member.isActive
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            ),
                          ),

                          // Admin Actions (Role changer & deactivate)
                          if (auth.isAdmin && !member.isOwner && !isCurrentUser) ...[
                            const SizedBox(width: 12),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (action) {
                                if (action == 'make_admin') {
                                  crm.updateMember(member.uid, role: 'admin');
                                } else if (action == 'make_employee') {
                                  crm.updateMember(member.uid,
                                      role: 'employee');
                                } else if (action == 'toggle_active') {
                                  crm.updateMember(member.uid,
                                      isActive: !member.isActive);
                                }
                              },
                              itemBuilder: (context) => [
                                if (member.role != 'admin')
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Promote to Admin'),
                                  ),
                                if (member.role != 'employee')
                                  const PopupMenuItem(
                                    value: 'make_employee',
                                    child: Text('Change to Employee'),
                                  ),
                                PopupMenuItem(
                                  value: 'toggle_active',
                                  child: Text(member.isActive
                                      ? 'Deactivate Access'
                                      : 'Reactivate Access'),
                                ),
                              ],
                            ),
                          ],
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

  void _showInviteDialog(BuildContext context, Agency? agency) {
    if (agency == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Team Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To add team members to your agency:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Have the employee open ClientFlow CRM and sign in with their Google account.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '2. Select "Join with Invite Code" on the workspace setup screen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              '3. Enter your Agency Invite Code:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  agency.inviteCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Code'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: agency.inviteCode));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite Code copied!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
