import 'bridge_config.dart';
import 'auth_config.dart';

class AppConfig {
  final BridgeConfig bridgeConfig;
  final AuthConfig authConfig;

  const AppConfig({
    required this.bridgeConfig,
    required this.authConfig,
  });

  const AppConfig.fromEnvironment()
      : bridgeConfig = const BridgeConfig.fromEnvironment(),
        authConfig = const AuthConfig.fromEnvironment();
}
