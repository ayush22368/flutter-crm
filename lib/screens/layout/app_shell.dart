import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';
import '../activities/activities_screen.dart';
import '../companies/companies_screen.dart';
import '../contacts/contacts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/leads_screen.dart';
import '../pipeline/pipeline_screen.dart';
import '../quotations/quotations_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../tasks/tasks_screen.dart';
import '../team/team_screen.dart';
import 'sidebar_nav.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  NavPage _currentPage = NavPage.dashboard;

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTheme.isDesktop(context);
    final auth = context.watch<AppAuthProvider>();
    final crm = context.watch<CrmProvider>();

    // Bind current user and agency context to CRM Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      crm.updateContext(
        agencyId: auth.currentAgency?.id,
        user: auth.user,
      );
    });

    Widget bodyContent;
    switch (_currentPage) {
      case NavPage.dashboard:
        bodyContent = DashboardScreen(
          onNavigate: (page) => setState(() => _currentPage = page),
        );
        break;
      case NavPage.leads:
        bodyContent = const LeadsScreen();
        break;
      case NavPage.pipeline:
        bodyContent = const PipelineScreen();
        break;
      case NavPage.contacts:
        bodyContent = const ContactsScreen();
        break;
      case NavPage.companies:
        bodyContent = const CompaniesScreen();
        break;
      case NavPage.tasks:
        bodyContent = const TasksScreen();
        break;
      case NavPage.activities:
        bodyContent = const ActivitiesScreen();
        break;
      case NavPage.quotations:
        bodyContent = const QuotationsScreen();
        break;
      case NavPage.reports:
        bodyContent = const ReportsScreen();
        break;
      case NavPage.team:
        bodyContent = const TeamScreen();
        break;
      case NavPage.settings:
        bodyContent = const SettingsScreen();
        break;
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SidebarNav(
              selectedPage: _currentPage,
              onPageSelected: (page) {
                setState(() => _currentPage = page);
              },
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    } else {
      // Mobile / Tablet with drawer
      return Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle(_currentPage)),
        ),
        drawer: Drawer(
          child: SidebarNav(
            selectedPage: _currentPage,
            onPageSelected: (page) {
              setState(() => _currentPage = page);
              Navigator.pop(context); // close drawer
            },
          ),
        ),
        body: bodyContent,
      );
    }
  }

  String _pageTitle(NavPage page) {
    switch (page) {
      case NavPage.dashboard:
        return 'Dashboard';
      case NavPage.leads:
        return 'Leads';
      case NavPage.pipeline:
        return 'Sales Pipeline';
      case NavPage.contacts:
        return 'Contacts';
      case NavPage.companies:
        return 'Companies';
      case NavPage.tasks:
        return 'Tasks & Follow-ups';
      case NavPage.activities:
        return 'Activities';
      case NavPage.quotations:
        return 'Quotations';
      case NavPage.reports:
        return 'Reports';
      case NavPage.team:
        return 'Team Members';
      case NavPage.settings:
        return 'Settings';
    }
  }
}
