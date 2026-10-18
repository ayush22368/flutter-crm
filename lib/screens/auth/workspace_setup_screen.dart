import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class WorkspaceSetupScreen extends StatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  State<WorkspaceSetupScreen> createState() => _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends State<WorkspaceSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Create form
  final _createFormKey = GlobalKey<FormState>();
  final _agencyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCurrency = '\$';
  final _taxController = TextEditingController(text: '18.0');

  // Join form
  final _joinFormKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _agencyNameController.dispose();
    _descriptionController.dispose();
    _taxController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Workspace Setup'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: AppTheme.primary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select or Create an Agency Workspace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Logged in as ${authProvider.user?.email ?? "User"}. You need an agency workspace to access CRM records.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),

                if (authProvider.errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      authProvider.errorMessage,
                      style: const TextStyle(
                        color: AppTheme.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tabs: Create vs Join
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    tabs: const [
                      Tab(text: 'Create New Agency'),
                      Tab(text: 'Join with Invite Code'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 340,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Create Agency Tab
                      Form(
                        key: _createFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _agencyNameController,
                              decoration: const InputDecoration(
                                labelText: 'Agency / Studio Name *',
                                hintText: 'e.g. Apex Software Labs',
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter agency name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Short Description',
                                hintText: 'e.g. Mobile Apps & Web Systems',
                                prefixIcon: Icon(Icons.info_outline),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCurrency,
                                    decoration: const InputDecoration(
                                      labelText: 'Currency',
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                          value: '\$', child: Text('\$ (USD)')),
                                      DropdownMenuItem(
                                          value: '₹', child: Text('₹ (INR)')),
                                      DropdownMenuItem(
                                          value: '€', child: Text('€ (EUR)')),
                                      DropdownMenuItem(
                                          value: '£', child: Text('£ (GBP)')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCurrency = val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    controller: _taxController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Default Tax %',
                                      suffixText: '%',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      if (_createFormKey.currentState!
                                          .validate()) {
                                        final tax = double.tryParse(
                                                _taxController.text) ??
                                            18.0;
                                        await authProvider.createAgency(
                                          agencyName:
                                              _agencyNameController.text.trim(),
                                          description: _descriptionController
                                              .text
                                              .trim(),
                                          currencySymbol: _selectedCurrency,
                                          defaultTaxPercent: tax,
                                        );
                                      }
                                    },
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Create & Launch Workspace'),
                            ),
                          ],
                        ),
                      ),

                      // Join Agency Tab
                      Form(
                        key: _joinFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Got an invite code from your agency owner?',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _inviteCodeController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: '6-Digit Invite Code *',
                                hintText: 'e.g. AB12CD',
                                prefixIcon: Icon(Icons.vpn_key_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter the invite code';
                                }
                                if (val.trim().length < 4) {
                                  return 'Code must be at least 4 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Once joined, you will be added as an Employee to the agency workspace and will be able to access leads, deals, and tasks.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      if (_joinFormKey.currentState!
                                          .validate()) {
                                        await authProvider.joinAgency(
                                          _inviteCodeController.text.trim(),
                                        );
                                      }
                                    },
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Join Agency Workspace'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
