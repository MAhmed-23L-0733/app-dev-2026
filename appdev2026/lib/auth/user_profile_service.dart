import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  const UserProfileService._();
  static const UserProfileService instance =
      UserProfileService._(); // [cite: 219]

  Future<void> ensureUserDocument({
    required User user,
    String? preferredName,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = FirebaseFirestore
        .instance
        .collection('users') // [cite: 219]
        .doc(user.uid); // [cite: 219]

    final String name = _resolveName(user, preferredName); // [cite: 220]
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref
        .get(); // [cite: 220]

    // Set on first login
    if (!snapshot.exists) {
      //
      await ref.set(<String, dynamic>{
        'email': user.email ?? '',
        'displayName': name,
        'createdAt': FieldValue.serverTimestamp(), // [cite: 222]
        'lastSignInAt': FieldValue.serverTimestamp(), // [cite: 222]
      });
      return; // [cite: 223]
    }

    // Update on subsequent logins
    await ref.set(<String, dynamic>{
      'email': user.email ?? '',
      'displayName': name,
      'lastSignInAt': FieldValue.serverTimestamp(), // [cite: 223]
    }, SetOptions(merge: true)); // [cite: 223]
  }

  Future<void> ensureUserDocumentSafely({
    required User user,
    String? preferredName,
  }) async {
    try {
      await ensureUserDocument(
        user: user,
        preferredName: preferredName,
      ); // [cite: 224]
    } catch (_) {} // [cite: 225]
  }

  String _resolveName(User user, String? preferredName) {
    final String fromInput = preferredName?.trim() ?? ''; // [cite: 225, 226]
    if (fromInput.isNotEmpty) {
      return fromInput; // [cite: 226, 227]
    }

    final String fromProfile = user.displayName?.trim() ?? ''; // [cite: 227]
    if (fromProfile.isNotEmpty) {
      // [cite: 228]
      return fromProfile;
    }

    final String fromEmail =
        user.email?.split('@').first.trim() ?? ''; // [cite: 228, 229]
    if (fromEmail.isNotEmpty) {
      return fromEmail; // [cite: 229]
    }

    return 'User'; // [cite: 229]
  }
}
