import 'package:flutter/material.dart';

import 'app/app.dart';
import 'bridge/native_bridge.dart';
import 'config/app_config.dart';
import 'features/auth/auth_controller.dart';
import 'features/share/share_controller.dart';

void main() {
  const config = AppConfig.fromEnvironment();
  final bridge = NativeBridge(config.bridgeConfig);

  final authController = AuthController(
    nativeBridge: bridge,
    authConfig: config.authConfig,
  );
  final shareController = ShareController(nativeBridge: bridge);

  runApp(App(
    authController: authController,
    shareController: shareController,
  ));
}
