import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agency_model.dart';
import '../models/lead_model.dart';
import '../models/deal_model.dart';
import '../models/contact_model.dart';
import '../models/company_model.dart';
import '../models/task_model.dart';
import '../models/activity_model.dart';
import '../models/quotation_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------------------------------------
  // USER & WORKSPACE MANAGEMENT
  // ----------------------------------------------------

  /// Get user document to find their current agency
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> saveUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoUrl': user.photoURL ?? '',
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Create a brand new Agency Workspace
  Future<Agency> createAgencyWorkspace({
    required String agencyName,
    required User user,
    String description = '',
    String currencySymbol = '\$',
    double defaultTaxPercent = 18.0,
  }) async {
    final agencyRef = _firestore.collection('agencies').doc();
    final inviteCode = _generateInviteCode();
    final now = DateTime.now();

    final agency = Agency(
      id: agencyRef.id,
      name: agencyName.trim(),
      description: description.trim(),
      businessEmail: user.email ?? '',
      currencySymbol: currencySymbol,
      defaultTaxPercent: defaultTaxPercent,
      inviteCode: inviteCode,
      ownerId: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    // Batch write to create agency, member, and link user profile
    final batch = _firestore.batch();
    batch.set(agencyRef, agency.toMap());

    final memberRef = agencyRef.collection('members').doc(user.uid);
    final member = AgencyMember(
      uid: user.uid,
      agencyId: agencyRef.id,
      email: user.email ?? '',
      displayName: user.displayName ?? 'Owner',
      photoUrl: user.photoURL ?? '',
      role: 'owner',
      isActive: true,
      joinedAt: now,
    );
    batch.set(memberRef, member.toMap());

    // Link user current agency
    final userRef = _firestore.collection('users').doc(user.uid);
    batch.set(userRef, {
      'currentAgencyId': agencyRef.id,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add initial activity
    final activityRef = agencyRef.collection('activities').doc();
    batch.set(activityRef, {
      'agencyId': agencyRef.id,
      'type': 'System',
      'title': 'Workspace Created',
      'description': '${user.displayName ?? "Owner"} created $agencyName workspace',
      'linkedEntityType': 'none',
      'linkedEntityId': '',
      'linkedEntityTitle': '',
      'createdByUid': user.uid,
      'createdByName': user.displayName ?? 'Owner',
      'createdAt': Timestamp.fromDate(now),
    });

    await batch.commit();
    return agency;
  }

  /// Join an existing Agency Workspace using an Invite Code
  Future<Agency> joinAgencyByInviteCode({
    required String inviteCode,
    required User user,
  }) async {
    final query = await _firestore
        .collection('agencies')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code. No agency found.');
    }

    final agencyDoc = query.docs.first;
    final agency = Agency.fromFirestore(agencyDoc);

    // Check if user is already a member
    final memberRef = agencyDoc.reference.collection('members').doc(user.uid);
    final memberDoc = await memberRef.get();

    final batch = _firestore.batch();
    if (!memberDoc.exists) {
      final newMember = AgencyMember(
        uid: user.uid,
        agencyId: agency.id,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Employee',
        photoUrl: user.photoURL ?? '',
        role: 'employee',
        isActive: true,
        joinedAt: DateTime.now(),
      );
      batch.set(memberRef, newMember.toMap());

      // Log join activity
      final actRef = agencyDoc.reference.collection('activities').doc();
      batch.set(actRef, {
        'agencyId': agency.id,
        'type': 'System',
        'title': 'New Member Joined',
        'description': '${user.displayName ?? user.email} joined the workspace',
        'linkedEntityType': 'none',
        'linkedEntityId': '',
        'linkedEntityTitle': '',
        'createdByUid': user.uid,
        'createdByName': user.displayName ?? 'Member',
        'createdAt': Timestamp.now(),
      });
    }

    final userRef = _firestore.collection('users').doc(user.uid);
    batch.set(userRef, {
      'currentAgencyId': agency.id,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return agency;
  }

  /// Stream current agency document
  Stream<Agency?> streamAgency(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .snapshots()
        .map((doc) => doc.exists ? Agency.fromFirestore(doc) : null);
  }

  /// Update agency profile
  Future<void> updateAgency(Agency agency) async {
    await _firestore
        .collection('agencies')
        .doc(agency.id)
        .update(agency.toMap());
  }

  /// Stream user membership for permissions
  Stream<AgencyMember?> streamMember(String agencyId, String uid) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AgencyMember.fromFirestore(doc) : null);
  }

  /// Stream all members of the agency
  Stream<List<AgencyMember>> streamAgencyMembers(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AgencyMember.fromFirestore(doc)).toList());
  }

  /// Update member role or active state
  Future<void> updateMember(
    String agencyId,
    String uid, {
    String? role,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (role != null) updates['role'] = role;
    if (isActive != null) updates['isActive'] = isActive;

    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('members')
        .doc(uid)
        .update(updates);
  }

  // ----------------------------------------------------
  // LEADS
  // ----------------------------------------------------

  Stream<List<Lead>> streamLeads(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('leads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Lead.fromFirestore(d)).toList());
  }

  /// Check for duplicates by email or phone (returns list of duplicate matching lead names)
  Future<List<String>> checkLeadDuplicates(
    String agencyId, {
    required String email,
    required String phone,
    String? excludeLeadId,
  }) async {
    final duplicates = <String>[];
    final leadsRef = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('leads');

    if (email.trim().isNotEmpty) {
      final emailSnap = await leadsRef
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(5)
          .get();
      for (var doc in emailSnap.docs) {
        if (doc.id != excludeLeadId) {
          final data = doc.data();
          duplicates.add('${data['fullName']} (Matching Email: $email)');
        }
      }
    }

    if (phone.trim().isNotEmpty) {
      final phoneSnap = await leadsRef
          .where('phone', isEqualTo: phone.trim())
          .limit(5)
          .get();
      for (var doc in phoneSnap.docs) {
        if (doc.id != excludeLeadId) {
          final data = doc.data();
          final text = '${data['fullName']} (Matching Phone: $phone)';
          if (!duplicates.contains(text)) duplicates.add(text);
        }
      }
    }

    return duplicates;
  }

  Future<void> addLead(String agencyId, Lead lead, User user) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('leads')
        .doc();

    final leadToSave = lead.copyWith(email: lead.email.trim().toLowerCase());
    final data = leadToSave.toMap();
    await ref.set(data);

    // Auto-log activity
    await addActivity(
      agencyId,
      ActivityItem(
        id: '',
        agencyId: agencyId,
        type: 'Note',
        title: 'New Lead Created',
        description: 'Lead "${lead.fullName}" added by ${user.displayName ?? user.email}',
        linkedEntityType: 'lead',
        linkedEntityId: ref.id,
        linkedEntityTitle: lead.fullName,
        createdByUid: user.uid,
        createdByName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateLead(String agencyId, Lead lead) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('leads')
        .doc(lead.id)
        .update(lead.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteLead(String agencyId, String leadId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('leads')
        .doc(leadId)
        .delete();
  }

  // ----------------------------------------------------
  // DEALS & PIPELINE
  // ----------------------------------------------------

  Stream<List<Deal>> streamDeals(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('deals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Deal.fromFirestore(d)).toList());
  }

  Future<void> addDeal(String agencyId, Deal deal, User user) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('deals')
        .doc();

    final initialHistory = DealStageHistory(
      fromStage: '',
      toStage: deal.stage,
      timestamp: DateTime.now(),
      changedByUid: user.uid,
      changedByName: user.displayName ?? 'User',
      note: 'Deal created in stage: ${deal.stage}',
    );

    final finalDeal = deal.copyWith(
      stageHistory: [initialHistory],
    );

    await ref.set(finalDeal.toMap());

    // Log Activity
    await addActivity(
      agencyId,
      ActivityItem(
        id: '',
        agencyId: agencyId,
        type: 'Stage Change',
        title: 'Deal Created: ${deal.title}',
        description: 'New deal in stage "${deal.stage}" with value ${deal.dealValue}',
        linkedEntityType: 'deal',
        linkedEntityId: ref.id,
        linkedEntityTitle: deal.title,
        createdByUid: user.uid,
        createdByName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateDeal(String agencyId, Deal deal) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('deals')
        .doc(deal.id)
        .update(deal.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> changeDealStage(
    String agencyId,
    Deal deal,
    String newStage, {
    String lostReason = '',
    String note = '',
    required User user,
  }) async {
    if (deal.stage == newStage) return;

    final historyItem = DealStageHistory(
      fromStage: deal.stage,
      toStage: newStage,
      timestamp: DateTime.now(),
      changedByUid: user.uid,
      changedByName: user.displayName ?? 'User',
      note: note.isNotEmpty ? note : 'Moved from ${deal.stage} to $newStage',
    );

    final updatedHistory = List<DealStageHistory>.from(deal.stageHistory)..add(historyItem);

    final updatedDeal = deal.copyWith(
      stage: newStage,
      lostReason: newStage == 'Lost' ? lostReason : deal.lostReason,
      stageHistory: updatedHistory,
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('deals')
        .doc(deal.id)
        .update(updatedDeal.toMap());

    // Log Stage Change activity
    await addActivity(
      agencyId,
      ActivityItem(
        id: '',
        agencyId: agencyId,
        type: 'Stage Change',
        title: 'Stage Changed: ${deal.title}',
        description: 'Moved from "${deal.stage}" to "$newStage"${lostReason.isNotEmpty ? " (Reason: $lostReason)" : ""}',
        linkedEntityType: 'deal',
        linkedEntityId: deal.id,
        linkedEntityTitle: deal.title,
        createdByUid: user.uid,
        createdByName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> deleteDeal(String agencyId, String dealId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('deals')
        .doc(dealId)
        .delete();
  }

  // ----------------------------------------------------
  // CONTACTS
  // ----------------------------------------------------

  Stream<List<Contact>> streamContacts(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('contacts')
        .orderBy('fullName', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Contact.fromFirestore(d)).toList());
  }

  Future<void> addContact(String agencyId, Contact contact) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('contacts')
        .doc();
    await ref.set(contact.toMap());
  }

  Future<void> updateContact(String agencyId, Contact contact) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('contacts')
        .doc(contact.id)
        .update(contact.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteContact(String agencyId, String contactId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('contacts')
        .doc(contactId)
        .delete();
  }

  // ----------------------------------------------------
  // COMPANIES
  // ----------------------------------------------------

  Stream<List<Company>> streamCompanies(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('companies')
        .orderBy('name', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Company.fromFirestore(d)).toList());
  }

  Future<void> addCompany(String agencyId, Company company) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('companies')
        .doc();
    await ref.set(company.toMap());
  }

  Future<void> updateCompany(String agencyId, Company company) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('companies')
        .doc(company.id)
        .update(company.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteCompany(String agencyId, String companyId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('companies')
        .doc(companyId)
        .delete();
  }

  // ----------------------------------------------------
  // TASKS & FOLLOW-UPS
  // ----------------------------------------------------

  Stream<List<TaskItem>> streamTasks(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('tasks')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskItem.fromFirestore(d)).toList());
  }

  Future<void> addTask(String agencyId, TaskItem task, User user) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('tasks')
        .doc();
    await ref.set(task.toMap());

    // Log Activity for task creation
    await addActivity(
      agencyId,
      ActivityItem(
        id: '',
        agencyId: agencyId,
        type: 'Note',
        title: 'Task Created: ${task.title}',
        description: '${task.type} due on ${task.dueDate.toLocal()}',
        linkedEntityType: task.linkedEntityType,
        linkedEntityId: task.linkedEntityId,
        linkedEntityTitle: task.linkedEntityTitle,
        createdByUid: user.uid,
        createdByName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateTask(String agencyId, TaskItem task) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('tasks')
        .doc(task.id)
        .update(task.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> toggleTaskCompleted(
    String agencyId,
    TaskItem task,
    bool isCompleted,
  ) async {
    final status = isCompleted ? 'Completed' : 'Pending';
    final completedAt = isCompleted ? DateTime.now() : null;

    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('tasks')
        .doc(task.id)
        .update({
      'status': status,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt) : null,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteTask(String agencyId, String taskId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ----------------------------------------------------
  // ACTIVITIES
  // ----------------------------------------------------

  Stream<List<ActivityItem>> streamActivities(String agencyId, {int limit = 100}) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => ActivityItem.fromFirestore(d)).toList());
  }

  Future<void> addActivity(String agencyId, ActivityItem activity) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('activities')
        .doc();
    await ref.set(activity.toMap());
  }

  // ----------------------------------------------------
  // QUOTATIONS
  // ----------------------------------------------------

  Stream<List<Quotation>> streamQuotations(String agencyId) {
    return _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('quotations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Quotation.fromFirestore(d)).toList());
  }

  Future<void> addQuotation(String agencyId, Quotation quotation, User user) async {
    final ref = _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('quotations')
        .doc();
    await ref.set(quotation.toMap());

    // Log Activity
    await addActivity(
      agencyId,
      ActivityItem(
        id: '',
        agencyId: agencyId,
        type: 'Note',
        title: 'Quotation Created: ${quotation.quoteNumber}',
        description: 'Quotation for "${quotation.clientName}" created with total ${quotation.finalTotal}',
        linkedEntityType: quotation.associatedDealId.isNotEmpty ? 'deal' : 'lead',
        linkedEntityId: quotation.associatedDealId.isNotEmpty
            ? quotation.associatedDealId
            : quotation.associatedLeadId,
        linkedEntityTitle: quotation.title,
        createdByUid: user.uid,
        createdByName: user.displayName ?? 'User',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateQuotation(String agencyId, Quotation quotation) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('quotations')
        .doc(quotation.id)
        .update(quotation.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> updateQuotationStatus(
    String agencyId,
    String quotationId,
    String status,
  ) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('quotations')
        .doc(quotationId)
        .update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteQuotation(String agencyId, String quotationId) async {
    await _firestore
        .collection('agencies')
        .doc(agencyId)
        .collection('quotations')
        .doc(quotationId)
        .delete();
  }

  // ----------------------------------------------------
  // HELPERS
  // ----------------------------------------------------

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
