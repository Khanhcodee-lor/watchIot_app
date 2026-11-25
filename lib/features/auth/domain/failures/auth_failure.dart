enum AuthFailureReason {
  invalidEmail,
  invalidCredentials,
  userDisabled,
  tooManyRequests,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
