enum AuthStatus { idle, loading, success, failure }

class AuthState {
  final AuthStatus status;
  final String? authorizationCode;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.authorizationCode,
    this.errorMessage,
  });
}
