import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:watchiot/features/auth/domain/entities/app_user.dart';
import 'package:watchiot/features/auth/domain/failures/auth_failure.dart';
import 'package:watchiot/features/auth/domain/usecases/auth_use_cases.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.getCurrentUserUseCase,
    required this.watchAuthStateUseCase,
    required this.signInUseCase,
    required this.sendPasswordResetUseCase,
    required this.signOutUseCase,
  }) {
    _user = getCurrentUserUseCase();
    _subscription = watchAuthStateUseCase().listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  final GetCurrentUserUseCase getCurrentUserUseCase;
  final WatchAuthStateUseCase watchAuthStateUseCase;
  final SignInUseCase signInUseCase;
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final SignOutUseCase signOutUseCase;
  StreamSubscription<AppUser?>? _subscription;

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn(String email, String password) async {
    _setBusy(true);
    try {
      await signInUseCase(email: email, password: password);
      _errorMessage = null;
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = _friendlyAuthError(error.reason);
      return false;
    } catch (_) {
      _errorMessage = 'Không thể đăng nhập. Vui lòng thử lại.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _setBusy(true);
    try {
      await sendPasswordResetUseCase(email);
      _errorMessage = null;
      return true;
    } on AuthFailure catch (error) {
      _errorMessage = _friendlyAuthError(error.reason);
      return false;
    } catch (_) {
      _errorMessage = 'Không gửi được email đặt lại mật khẩu.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() => signOutUseCase();

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _friendlyAuthError(AuthFailureReason reason) {
    switch (reason) {
      case AuthFailureReason.invalidEmail:
        return 'Địa chỉ email không hợp lệ.';
      case AuthFailureReason.invalidCredentials:
        return 'Email hoặc mật khẩu chưa chính xác.';
      case AuthFailureReason.userDisabled:
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case AuthFailureReason.tooManyRequests:
        return 'Bạn thử quá nhiều lần. Vui lòng đợi một lúc.';
      case AuthFailureReason.network:
        return 'Không có kết nối mạng.';
      case AuthFailureReason.unknown:
        return 'Đăng nhập thất bại. Vui lòng thử lại.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
