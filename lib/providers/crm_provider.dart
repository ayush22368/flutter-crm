import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/agency_model.dart';
import '../models/lead_model.dart';
import '../models/deal_model.dart';
import '../models/contact_model.dart';
import '../models/company_model.dart';
import '../models/task_model.dart';
import '../models/activity_model.dart';
import '../models/quotation_model.dart';
import '../services/firestore_service.dart';

class CrmProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  String? _currentAgencyId;
  User? _currentUser;

  bool _isLoading = true;
  String _errorMessage = '';

  List<Lead> _leads = [];
  List<Deal> _deals = [];
  List<Contact> _contacts = [];
  List<Company> _companies = [];
  List<TaskItem> _tasks = [];
  List<ActivityItem> _activities = [];
  List<Quotation> _quotations = [];
  List<AgencyMember> _members = [];

  StreamSubscription? _leadsSub;
  StreamSubscription? _dealsSub;
  StreamSubscription? _contactsSub;
  StreamSubscription? _companiesSub;
  StreamSubscription? _tasksSub;
  StreamSubscription? _activitiesSub;
  StreamSubscription? _quotationsSub;
  StreamSubscription? _membersSub;

  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  List<Lead> get leads => _leads;
  List<Deal> get deals => _deals;
  List<Contact> get contacts => _contacts;
  List<Company> get companies => _companies;
  List<TaskItem> get tasks => _tasks;
  List<ActivityItem> get activities => _activities;
  List<Quotation> get quotations => _quotations;
  List<AgencyMember> get members => _members;

  // ----------------------------------------------------
  // COMPUTED DASHBOARD METRICS (Real calculations only!)
  // ----------------------------------------------------

  int get totalLeads => _leads.where((l) => !l.isArchived).length;

  int get newLeadsThisMonth {
    final now = DateTime.now();
    return _leads.where((l) {
      if (l.isArchived) return false;
      return l.createdAt.year == now.year && l.createdAt.month == now.month;
    }).length;
  }

  int get activeDeals => _deals.where((d) => d.isOpen).length;

  int get wonDealsThisMonth {
    final now = DateTime.now();
    return _deals.where((d) {
      if (!d.isWon) return false;
      return d.updatedAt.year == now.year && d.updatedAt.month == now.month;
    }).length;
  }

  int get lostDeals => _deals.where((d) => d.isLost).length;

  double get openPipelineValue {
    return _deals
        .where((d) => d.isOpen)
        .fold(0.0, (sum, d) => sum + d.dealValue);
  }

  double get wonDealsValue {
    return _deals
        .where((d) => d.isWon)
        .fold(0.0, (sum, d) => sum + d.dealValue);
  }

  int get followUpsDueToday {
    return _tasks.where((t) => t.isDueToday).length;
  }

  int get overdueFollowUps {
    return _tasks.where((t) => t.isOverdue).length;
  }

  int get upcomingTasks {
    final now = DateTime.now();
    return _tasks
        .where((t) => !t.isCompleted && t.dueDate.isAfter(now))
        .length;
  }

  List<ActivityItem> get recentActivities {
    return _activities.take(8).toList();
  }

  Map<String, int> get leadsBySource {
    final map = <String, int>{};
    for (var source in Lead.sources) {
      map[source] = 0;
    }
    for (var lead in _leads.where((l) => !l.isArchived)) {
      map[lead.source] = (map[lead.source] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get leadsByStatus {
    final map = <String, int>{};
    for (var status in Lead.statuses) {
      map[status] = 0;
    }
    for (var lead in _leads.where((l) => !l.isArchived)) {
      map[lead.status] = (map[lead.status] ?? 0) + 1;
    }
    return map;
  }

  Map<String, double> get dealsValueByStage {
    final map = <String, double>{};
    for (var stage in Deal.stages) {
      map[stage] = 0.0;
    }
    for (var deal in _deals) {
      map[deal.stage] = (map[deal.stage] ?? 0.0) + deal.dealValue;
    }
    return map;
  }

  Map<String, int> get dealsCountByStage {
    final map = <String, int>{};
    for (var stage in Deal.stages) {
      map[stage] = 0;
    }
    for (var deal in _deals) {
      map[deal.stage] = (map[deal.stage] ?? 0) + 1;
    }
    return map;
  }

  double get salesConversionRate {
    final closedDeals = _deals.where((d) => d.isWon || d.isLost).length;
    if (closedDeals == 0) return 0.0;
    final wonCount = _deals.where((d) => d.isWon).length;
    return (wonCount / closedDeals) * 100.0;
  }

  Map<String, int> get lostDealReasons {
    final map = <String, int>{};
    for (var deal in _deals.where((d) => d.isLost)) {
      final reason = deal.lostReason.trim().isNotEmpty
          ? deal.lostReason.trim()
          : 'No reason specified';
      map[reason] = (map[reason] ?? 0) + 1;
    }
    return map;
  }

  // ----------------------------------------------------
  // WORKSPACE BINDING
  // ----------------------------------------------------

  void updateContext({required String? agencyId, required User? user}) {
    if (_currentAgencyId == agencyId && _currentUser?.uid == user?.uid) {
      return;
    }

    _currentAgencyId = agencyId;
    _currentUser = user;

    if (agencyId != null && agencyId.isNotEmpty) {
      _subscribeAll(agencyId);
    } else {
      _unsubscribeAll();
      _clearData();
    }
  }

  void _subscribeAll(String agencyId) {
    _unsubscribeAll();
    _isLoading = true;
    notifyListeners();

    _leadsSub = _firestoreService.streamLeads(agencyId).listen((data) {
      _leads = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _dealsSub = _firestoreService.streamDeals(agencyId).listen((data) {
      _deals = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _contactsSub = _firestoreService.streamContacts(agencyId).listen((data) {
      _contacts = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _companiesSub = _firestoreService.streamCompanies(agencyId).listen((data) {
      _companies = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _tasksSub = _firestoreService.streamTasks(agencyId).listen((data) {
      _tasks = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _activitiesSub =
        _firestoreService.streamActivities(agencyId, limit: 100).listen((data) {
      _activities = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _quotationsSub =
        _firestoreService.streamQuotations(agencyId).listen((data) {
      _quotations = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);

    _membersSub =
        _firestoreService.streamAgencyMembers(agencyId).listen((data) {
      _members = data;
      _isLoading = false;
      notifyListeners();
    }, onError: _handleError);
  }

  void _unsubscribeAll() {
    _leadsSub?.cancel();
    _dealsSub?.cancel();
    _contactsSub?.cancel();
    _companiesSub?.cancel();
    _tasksSub?.cancel();
    _activitiesSub?.cancel();
    _quotationsSub?.cancel();
    _membersSub?.cancel();
  }

  void _clearData() {
    _leads = [];
    _deals = [];
    _contacts = [];
    _companies = [];
    _tasks = [];
    _activities = [];
    _quotations = [];
    _members = [];
    _isLoading = false;
    notifyListeners();
  }

  void _handleError(dynamic error) {
    _errorMessage = error.toString();
    _isLoading = false;
    notifyListeners();
  }

  // ----------------------------------------------------
  // LEADS ACTIONS
  // ----------------------------------------------------

  Future<List<String>> checkLeadDuplicates({
    required String email,
    required String phone,
    String? excludeLeadId,
  }) async {
    if (_currentAgencyId == null) return [];
    return await _firestoreService.checkLeadDuplicates(
      _currentAgencyId!,
      email: email,
      phone: phone,
      excludeLeadId: excludeLeadId,
    );
  }

  Future<void> addLead(Lead lead) async {
    if (_currentAgencyId == null || _currentUser == null) return;
    await _firestoreService.addLead(_currentAgencyId!, lead, _currentUser!);
  }

  Future<void> updateLead(Lead lead) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateLead(_currentAgencyId!, lead);
  }

  Future<void> archiveLead(Lead lead, bool archive) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateLead(
      _currentAgencyId!,
      lead.copyWith(isArchived: archive),
    );
  }

  Future<void> deleteLead(String leadId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteLead(_currentAgencyId!, leadId);
  }

  // ----------------------------------------------------
  // DEALS ACTIONS
  // ----------------------------------------------------

  Future<void> addDeal(Deal deal) async {
    if (_currentAgencyId == null || _currentUser == null) return;
    await _firestoreService.addDeal(_currentAgencyId!, deal, _currentUser!);
  }

  Future<void> updateDeal(Deal deal) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateDeal(_currentAgencyId!, deal);
  }

  Future<void> changeDealStage(
    Deal deal,
    String newStage, {
    String lostReason = '',
    String note = '',
  }) async {
    if (_currentAgencyId == null || _currentUser == null) return;
    await _firestoreService.changeDealStage(
      _currentAgencyId!,
      deal,
      newStage,
      lostReason: lostReason,
      note: note,
      user: _currentUser!,
    );
  }

  Future<void> deleteDeal(String dealId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteDeal(_currentAgencyId!, dealId);
  }

  // ----------------------------------------------------
  // CONTACTS ACTIONS
  // ----------------------------------------------------

  Future<void> addContact(Contact contact) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.addContact(_currentAgencyId!, contact);
  }

  Future<void> updateContact(Contact contact) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateContact(_currentAgencyId!, contact);
  }

  Future<void> deleteContact(String contactId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteContact(_currentAgencyId!, contactId);
  }

  // ----------------------------------------------------
  // COMPANIES ACTIONS
  // ----------------------------------------------------

  Future<void> addCompany(Company company) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.addCompany(_currentAgencyId!, company);
  }

  Future<void> updateCompany(Company company) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateCompany(_currentAgencyId!, company);
  }

  Future<void> deleteCompany(String companyId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteCompany(_currentAgencyId!, companyId);
  }

  // ----------------------------------------------------
  // TASKS ACTIONS
  // ----------------------------------------------------

  Future<void> addTask(TaskItem task) async {
    if (_currentAgencyId == null || _currentUser == null) return;
    await _firestoreService.addTask(_currentAgencyId!, task, _currentUser!);
  }

  Future<void> updateTask(TaskItem task) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateTask(_currentAgencyId!, task);
  }

  Future<void> toggleTaskCompleted(TaskItem task, bool isCompleted) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.toggleTaskCompleted(
      _currentAgencyId!,
      task,
      isCompleted,
    );
  }

  Future<void> deleteTask(String taskId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteTask(_currentAgencyId!, taskId);
  }

  // ----------------------------------------------------
  // ACTIVITIES ACTIONS
  // ----------------------------------------------------

  Future<void> addActivity(ActivityItem activity) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.addActivity(_currentAgencyId!, activity);
  }

  // ----------------------------------------------------
  // QUOTATIONS ACTIONS
  // ----------------------------------------------------

  Future<void> addQuotation(Quotation quotation) async {
    if (_currentAgencyId == null || _currentUser == null) return;
    await _firestoreService.addQuotation(
      _currentAgencyId!,
      quotation,
      _currentUser!,
    );
  }

  Future<void> updateQuotation(Quotation quotation) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateQuotation(_currentAgencyId!, quotation);
  }

  Future<void> updateQuotationStatus(String quotationId, String status) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateQuotationStatus(
      _currentAgencyId!,
      quotationId,
      status,
    );
  }

  Future<void> deleteQuotation(String quotationId) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.deleteQuotation(_currentAgencyId!, quotationId);
  }

  // ----------------------------------------------------
  // TEAM MEMBERS ACTIONS
  // ----------------------------------------------------

  Future<void> updateMember(
    String uid, {
    String? role,
    bool? isActive,
  }) async {
    if (_currentAgencyId == null) return;
    await _firestoreService.updateMember(
      _currentAgencyId!,
      uid,
      role: role,
      isActive: isActive,
    );
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }
}
