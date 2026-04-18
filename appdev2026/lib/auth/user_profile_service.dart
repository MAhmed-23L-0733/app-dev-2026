import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/currency_service.dart';
import '../services/budget_firestore_service.dart';

class UserProfileService {
  const UserProfileService._();
  static const UserProfileService instance = UserProfileService._();

  Future<void> ensureUserDocument({
    required User user,
    String? preferredName,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid);

    final String name = _resolveName(user, preferredName);
    final Timestamp createdAt = Timestamp.fromDate(
      user.metadata.creationTime ?? DateTime.now(),
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    final String preferredCurrency = _resolveCurrencyCode(
      snapshot.data()?['preferredCurrency'] as String?,
    );

    await ref.set(<String, dynamic>{
      'email': user.email ?? '',
      'displayName': name,
      'photoURL': user.photoURL ?? '',
      'createdAt': createdAt,
      'lastSignInAt': FieldValue.serverTimestamp(),
      'preferredCurrency': preferredCurrency,
    }, SetOptions(merge: true));

    CurrencyPreferenceController.instance.setCurrencyCode(preferredCurrency);
    await BudgetFirestoreService.instance.ensureBudgetNodes(user: user);
  }

  Future<void> loadPreferredCurrencyForUser(User user) async {
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    final String preferredCurrency = _resolveCurrencyCode(
      snapshot.data()?['preferredCurrency'] as String?,
    );

    CurrencyPreferenceController.instance.setCurrencyCode(preferredCurrency);
  }

  Future<void> updatePreferredCurrency(User user, String currencyCode) async {
    final String normalizedCurrency = _resolveCurrencyCode(currencyCode);
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid);

    await ref.set(<String, dynamic>{
      'preferredCurrency': normalizedCurrency,
      'lastSignInAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    CurrencyPreferenceController.instance.setCurrencyCode(normalizedCurrency);
  }

  Future<bool> ensureUserDocumentSafely({
    required User user,
    String? preferredName,
  }) async {
    try {
      await ensureUserDocument(user: user, preferredName: preferredName);
      return true;
    } catch (error, stackTrace) {
      debugPrint('Firestore profile sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  String _resolveName(User user, String? preferredName) {
    final String fromInput = preferredName?.trim() ?? '';
    if (fromInput.isNotEmpty) {
      return fromInput;
    }

    final String fromProfile = user.displayName?.trim() ?? '';
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }

    final String fromEmail = user.email?.split('@').first.trim() ?? '';
    if (fromEmail.isNotEmpty) {
      return fromEmail;
    }

    return 'User';
  }

  String _resolveCurrencyCode(String? code) {
    return CurrencyPreferenceController.instance.optionFor(code ?? 'PKR').code;
  }
}
