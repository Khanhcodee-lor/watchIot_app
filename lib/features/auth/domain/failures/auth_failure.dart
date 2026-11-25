enum AuthFailureReason {
  invalidEmail,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  operationNotAllowed,
  userDisabled,
  tooManyRequests,
  network,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
