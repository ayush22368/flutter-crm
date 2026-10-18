import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/agency_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  uninitialized,
  authenticating,
  authenticated,
  unauthenticated,
}

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  Agency? _currentAgency;
  AgencyMember? _currentMember;
  AuthStatus _status = AuthStatus.uninitialized;
  String _errorMessage = '';
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<Agency?>? _agencySubscription;
  StreamSubscription<AgencyMember?>? _memberSubscription;

  User? get user => _user;
  Agency? get currentAgency => _currentAgency;
  AgencyMember? get currentMember => _currentMember;
  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get hasAgency => _currentAgency != null;
  bool get isOwner => _currentMember?.isOwner ?? false;
  bool get isAdmin => _currentMember?.isAdmin ?? false;
  bool get isEmployee => _currentMember?.isEmployee ?? true;
  bool get isMemberActive => _currentMember?.isActive ?? true;

  AppAuthProvider() {
    _init();
  }

  void _init() {
    _authSubscription = _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentAgency = null;
        _currentMember = null;
        _cancelAgencySubscriptions();
        notifyListeners();
      } else {
        _status = AuthStatus.authenticated;
        await _firestoreService.saveUserProfile(user);
        await _loadUserAgency(user.uid);
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserAgency(String uid) async {
    try {
      final userProfile = await _firestoreService.getUserProfile(uid);
      final currentAgencyId = userProfile?['currentAgencyId'] as String?;

      if (currentAgencyId != null && currentAgencyId.isNotEmpty) {
        _subscribeToAgency(currentAgencyId, uid);
      } else {
        _currentAgency = null;
        _currentMember = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user agency: $e');
    }
  }

  void _subscribeToAgency(String agencyId, String uid) {
    _cancelAgencySubscriptions();

    _agencySubscription = _firestoreService.streamAgency(agencyId).listen((agency) {
      _currentAgency = agency;
      notifyListeners();
    });

    _memberSubscription = _firestoreService.streamMember(agencyId, uid).listen((member) {
      _currentMember = member;
      notifyListeners();
    });
  }

  void _cancelAgencySubscriptions() {
    _agencySubscription?.cancel();
    _agencySubscription = null;
    _memberSubscription?.cancel();
    _memberSubscription = null;
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final cred = await _authService.signInWithGoogle();
      _isLoading = false;
      if (cred?.user != null) {
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Create new agency workspace
  Future<bool> createAgency({
    required String agencyName,
    String description = '',
    String currencySymbol = '\$',
    double defaultTaxPercent = 18.0,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final agency = await _firestoreService.createAgencyWorkspace(
        agencyName: agencyName,
        user: _user!,
        description: description,
        currencySymbol: currencySymbol,
        defaultTaxPercent: defaultTaxPercent,
      );
      _subscribeToAgency(agency.id, _user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Join existing agency with invite code
  Future<bool> joinAgency(String inviteCode) async {
    if (_user == null) return false;
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final agency = await _firestoreService.joinAgencyByInviteCode(
        inviteCode: inviteCode,
        user: _user!,
      );
      _subscribeToAgency(agency.id, _user!.uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  /// Update agency profile
  Future<void> updateAgencyProfile(Agency updatedAgency) async {
    if (_user == null || !isAdmin) return;
    try {
      await _firestoreService.updateAgency(updatedAgency);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _cancelAgencySubscriptions();
    _currentAgency = null;
    _currentMember = null;
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelAgencySubscriptions();
    super.dispose();
  }
}
