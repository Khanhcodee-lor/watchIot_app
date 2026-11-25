import 'package:firebase_auth/firebase_auth.dart';
import 'package:watchiot/features/auth/domain/failures/auth_failure.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFailureReason(error.code));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFailureReason(error.code));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_mapFailureReason(error.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  AuthFailureReason _mapFailureReason(String code) {
    switch (code) {
      case 'invalid-email':
        return AuthFailureReason.invalidEmail;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthFailureReason.invalidCredentials;
      case 'email-already-in-use':
        return AuthFailureReason.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailureReason.weakPassword;
      case 'operation-not-allowed':
        return AuthFailureReason.operationNotAllowed;
      case 'user-disabled':
        return AuthFailureReason.userDisabled;
      case 'too-many-requests':
        return AuthFailureReason.tooManyRequests;
      case 'network-request-failed':
        return AuthFailureReason.network;
      default:
        return AuthFailureReason.unknown;
    }
  }
}
