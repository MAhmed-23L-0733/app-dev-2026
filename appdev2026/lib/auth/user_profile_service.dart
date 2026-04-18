import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set(<String, dynamic>{
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'photoUrl': user.photoURL,
        'providerIds': user.providerData
            .map((UserInfo info) => info.providerId)
            .where((String id) => id.isNotEmpty)
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignInAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await ref.set(<String, dynamic>{
      'name': name,
      'email': user.email,
      'photoUrl': user.photoURL,
      'providerIds': user.providerData
          .map((UserInfo info) => info.providerId)
          .where((String id) => id.isNotEmpty)
          .toList(),
      'lastSignInAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureUserDocumentSafely({
    required User user,
    String? preferredName,
  }) async {
    try {
      await ensureUserDocument(user: user, preferredName: preferredName);
    } catch (_) {}
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
}
