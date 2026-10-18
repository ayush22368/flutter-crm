import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _taxController;
  late String _currency;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final agency = context.read<AppAuthProvider>().currentAgency;
      _nameController = TextEditingController(text: agency?.name ?? '');
      _descController = TextEditingController(text: agency?.description ?? '');
      _emailController =
          TextEditingController(text: agency?.businessEmail ?? '');
      _phoneController = TextEditingController(text: agency?.phone ?? '');
      _websiteController = TextEditingController(text: agency?.website ?? '');
      _addressController = TextEditingController(text: agency?.address ?? '');
      _taxController = TextEditingController(
          text: (agency?.defaultTaxPercent ?? 18.0).toString());
      _currency = agency?.currencySymbol ?? '\$';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final agency = auth.currentAgency;
    final user = auth.user;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings & Preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your agency identity, user account, currency, and quotation defaults.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // User Account Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your User Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primary,
                          backgroundImage: user?.photoURL != null &&
                                  user!.photoURL!.isNotEmpty
                              ? NetworkImage(user.photoURL!)
                              : null,
                          child: user?.photoURL == null ||
                                  user!.photoURL!.isEmpty
                              ? Text(
                                  (user?.displayName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? 'Agency Member',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      auth.currentMember?.role.toUpperCase() ??
                                          'EMPLOYEE',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Authenticated via Google Sign-In',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Sign Out'),
                          onPressed: () => auth.signOut(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Agency Profile Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
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
                                'Agency Workspace Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAdmin
                                    ? 'These details appear on your client PDF quotations.'
                                    : 'Only Agency Owners/Admins can edit agency details.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          if (isAdmin)
                            ElevatedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate() &&
                                          agency != null) {
                                        setState(() => _isSaving = true);
                                        final tax = double.tryParse(
                                                _taxController.text) ??
                                            18.0;
                                        final updated = agency.copyWith(
                                          name: _nameController.text.trim(),
                                          description:
                                              _descController.text.trim(),
                                          businessEmail:
                                              _emailController.text.trim(),
                                          phone: _phoneController.text.trim(),
                                          website:
                                              _websiteController.text.trim(),
                                          address:
                                              _addressController.text.trim(),
                                          currencySymbol: _currency,
                                          defaultTaxPercent: tax,
                                        );
                                        await auth.updateAgencyProfile(updated);
                                        setState(() => _isSaving = false);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Agency profile updated successfully!'),
                                              backgroundColor: AppTheme.success,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Save Profile'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Agency Name *',
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Enter agency name'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _descController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Tagline / Focus',
                                hintText: 'Mobile & Custom Web Agency',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Business Email',
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Business Phone',
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _websiteController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Agency Website',
                                prefixIcon: Icon(Icons.language),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _addressController,
                              enabled: isAdmin,
                              decoration: const InputDecoration(
                                labelText: 'Office / Billing Address',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Default Currency Symbol',
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
                              onChanged: isAdmin
                                  ? (val) {
                                      if (val != null) {
                                        setState(() => _currency = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _taxController,
                              enabled: isAdmin,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Default Quotation Tax (%)',
                                suffixText: '%',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
