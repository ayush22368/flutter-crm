import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/company_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/crm_provider.dart';
import '../../theme/app_theme.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    final crm = context.watch<CrmProvider>();
    final auth = context.watch<AppAuthProvider>();

    final filteredCompanies = crm.companies.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = c.name.toLowerCase().contains(q);
        final matchesIndustry = c.industry.toLowerCase().contains(q);
        final matchesEmail = c.email.toLowerCase().contains(q);
        if (!matchesName && !matchesIndustry && !matchesEmail) return false;
      }
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
                      'Companies & Client Accounts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage businesses, startups, and enterprise clients you build software for.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Company'),
                  onPressed: () => _showAddEditCompanyDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by company name, industry...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Companies List
            Expanded(
              child: filteredCompanies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.domain_outlined,
                              size: 48, color: AppTheme.textLight),
                          const SizedBox(height: 12),
                          const Text(
                            'No companies registered yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your client business accounts to track deals and contacts.',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Company'),
                            onPressed: () => _showAddEditCompanyDialog(context),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      child: ListView.separated(
                        itemCount: filteredCompanies.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: AppTheme.borderLight, height: 1),
                        itemBuilder: (context, index) {
                          final company = filteredCompanies[index];
                          final companyDeals = crm.deals
                              .where((d) =>
                                  d.companyName.toLowerCase() ==
                                  company.name.toLowerCase())
                              .length;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.domain,
                                  color: AppTheme.primary, size: 22),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  company.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgLight,
                                    borderRadius: BorderRadius.circular(4),
                                    border:
                                        Border.all(color: AppTheme.borderLight),
                                  ),
                                  child: Text(
                                    company.industry,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 14,
                                children: [
                                  if (company.website.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.language,
                                            size: 13,
                                            color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Text(company.website,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  if (company.email.isNotEmpty)
                                    Text('• ${company.email}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted)),
                                  Text('• $companyDeals Active Deals',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primary)),
                                ],
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _showAddEditCompanyDialog(context,
                                      company: company);
                                } else if (val == 'delete') {
                                  crm.deleteCompany(company.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit Company'),
                                    ],
                                  ),
                                ),
                                if (auth.isAdmin)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 16, color: AppTheme.danger),
                                        SizedBox(width: 8),
                                        Text('Delete',
                                            style: TextStyle(
                                                color: AppTheme.danger)),
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

  void _showAddEditCompanyDialog(BuildContext context, {Company? company}) {
    final formKey = GlobalKey<FormState>();
    final crm = context.read<CrmProvider>();
    final auth = context.read<AppAuthProvider>();

    final nameController = TextEditingController(text: company?.name ?? '');
    final industryController =
        TextEditingController(text: company?.industry ?? 'Technology');
    final websiteController =
        TextEditingController(text: company?.website ?? '');
    final emailController = TextEditingController(text: company?.email ?? '');
    final phoneController = TextEditingController(text: company?.phone ?? '');
    final addressController =
        TextEditingController(text: company?.address ?? '');
    final notesController = TextEditingController(text: company?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(company == null ? 'Add Company' : 'Edit Company'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name *',
                      prefixIcon: Icon(Icons.domain),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter company name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: industryController,
                          decoration: const InputDecoration(
                            labelText: 'Industry',
                            hintText: 'e.g. Fintech, Healthcare, SaaS',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website',
                            prefixIcon: Icon(Icons.language),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Business Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Headquarters Address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
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
                if (company == null) {
                  final newCompany = Company(
                    id: '',
                    agencyId: auth.currentAgency!.id,
                    name: nameController.text.trim(),
                    industry: industryController.text.trim(),
                    website: websiteController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    notes: notesController.text.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  crm.addCompany(newCompany);
                } else {
                  final updated = company.copyWith(
                    name: nameController.text.trim(),
                    industry: industryController.text.trim(),
                    website: websiteController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    notes: notesController.text.trim(),
                    updatedAt: DateTime.now(),
                  );
                  crm.updateCompany(updated);
                }
                Navigator.pop(ctx);
              }
            },
            child: Text(company == null ? 'Save Company' : 'Update Company'),
          ),
        ],
      ),
    );
  }
}
