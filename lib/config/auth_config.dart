class AuthConfig {
  final String clientId;
  final String scope;

  const AuthConfig({
    required this.clientId,
    required this.scope,
  });

  const AuthConfig.fromEnvironment()
      : clientId = const String.fromEnvironment('AUTH_CLIENT_ID'),
        scope = const String.fromEnvironment('AUTH_SCOPE');

  bool get isValid => clientId.trim().isNotEmpty && scope.trim().isNotEmpty;
}
