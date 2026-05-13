import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthResult { success, cancelled, conflict, error }

/// Authentication service for Google Sign-In and Apple Sign-In.
/// Links credentials to existing anonymous Firebase accounts so
/// purchase history and game progress are preserved.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  /// Current user
  static User? get currentUser => _auth.currentUser;

  /// Current user ID
  static String? get currentUid => _auth.currentUser?.uid;

  /// Whether the user has linked a real identity (not anonymous)
  static bool get isLinked {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any(
      (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
    );
  }

  /// Whether the current session is an anonymous guest account.
  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Sign in with Google and link to existing anonymous account.
  /// Returns AuthResult to indicate conflict or success.
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled; // User cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Try to link to existing anonymous account first
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await user.linkWithCredential(credential);
          print('[AUTH] Google account linked to anonymous user');
          return AuthResult.success;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // This Google account is already linked to another user.
            // We will sign them in to the existing account but signal a conflict
            await _auth.signInWithCredential(credential);
            print('[AUTH] Signed in with existing Google account - CONFLICT');
            return AuthResult.conflict;
          }
          rethrow;
        }
      } else {
        // No anonymous user, just sign in
        await _auth.signInWithCredential(credential);
        return AuthResult.success;
      }
    } catch (e) {
      print('[AUTH] Google Sign-In error: $e');
      return AuthResult.error;
    }
  }

  /// Sign in with Apple and link to existing anonymous account.
  static Future<AuthResult> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        try {
          await user.linkWithProvider(appleProvider);
          print('[AUTH] Apple account linked to anonymous user');
          return AuthResult.success;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            await _auth.signInWithProvider(appleProvider);
            print('[AUTH] Signed in with existing Apple account - CONFLICT');
            return AuthResult.conflict;
          }
          rethrow;
        }
      } else {
        await _auth.signInWithProvider(appleProvider);
        return AuthResult.success;
      }
    } catch (e) {
      print('[AUTH] Apple Sign-In error: $e');
      return AuthResult.error;
    }
  }

  /// Reauthenticate user for sensitive operations like account deletion
  static Future<void> reauthenticate() async {
    final user = _auth.currentUser;
    if (user == null) return;

    bool isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    bool isApple = user.providerData.any((p) => p.providerId == 'apple.com');

    if (isGoogle) {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }
    } else if (isApple) {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      await user.reauthenticateWithProvider(appleProvider);
    }
  }

  /// Delete Firebase Account and create a fresh anonymous session
  static Future<void> deleteAccount() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;

    if (firebaseUser.isAnonymous) {
      throw FirebaseAuthException(
        code: 'anonymous-delete-disabled',
        message:
            'Anonim hesaplar uygulama icinden silinemez. Once Google veya Apple ile baglan.',
      );
    }

    try {
      await firebaseUser.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print('[AUTH] Deletion requires recent login. Reauthenticating...');
        await reauthenticate();
        await firebaseUser.delete();
      } else {
        rethrow;
      }
    }

    // Create new anonymous session after deletion
    await _googleSignIn.signOut();
    await _auth.signInAnonymously();
    print('[AUTH] Account deleted. New anonymous session started.');
  }

  /// Sign out and go back to anonymous
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await _auth.signInAnonymously();
  }

  /// Display name from provider
  static String get displayName {
    final user = _auth.currentUser;
    if (user == null) return 'Anonim Usta';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    return 'Mechanic_${user.uid.substring(0, 6)}';
  }

  /// Whether to show Apple Sign-In (iOS only)
  static bool get showAppleSignIn => Platform.isIOS;
}
