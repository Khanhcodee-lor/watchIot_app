import 'package:watchiot/features/auth/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> watchAuthState();
  Future<void> signIn({required String email, required String password});
  Future<void> register({required String email, required String password});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}
