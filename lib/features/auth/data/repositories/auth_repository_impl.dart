import 'package:firebase_auth/firebase_auth.dart';
import 'package:watchiot/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:watchiot/features/auth/domain/entities/app_user.dart';
import 'package:watchiot/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  @override
  AppUser? get currentUser => _toAppUser(_dataSource.currentUser);

  @override
  Stream<AppUser?> watchAuthState() =>
      _dataSource.authStateChanges.map(_toAppUser);

  @override
  Future<void> signIn({required String email, required String password}) {
    return _dataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _dataSource.sendPasswordReset(email);
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(uid: user.uid, email: user.email ?? '');
  }
}
