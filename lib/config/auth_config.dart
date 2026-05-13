class AuthConfig {
  final String clientId;
  final String scope;

  const AuthConfig({
    required this.clientId,
    required this.scope,
  });

  const AuthConfig.fromEnvironment()
      : clientId = const String.fromEnvironment(
          'AUTH_CLIENT_ID',
          defaultValue: '2619c75d-e809-4115-a83c-1b58ee5ae6c8',
        ),
        scope = const String.fromEnvironment(
          'AUTH_SCOPE',
          defaultValue:
              'offline+openid+paotangid.citizen',
        );

  bool get isValid => clientId.trim().isNotEmpty && scope.trim().isNotEmpty;
}
