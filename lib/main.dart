import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/console_log.dart';
import 'bridge/native_bridge.dart';
import 'config/app_config.dart';
import 'features/auth/auth_controller.dart';
import 'features/payment/payment_controller.dart';
import 'features/save_image/save_image_controller.dart';
import 'features/share/share_controller.dart';

void main() {
  const config = AppConfig.fromEnvironment();
  final bridge = NativeBridge(config.bridgeConfig);
  final consoleLog = ConsoleLogService();

  final authController = AuthController(nativeBridge: bridge, consoleLog: consoleLog);
  final shareController = ShareController(nativeBridge: bridge, consoleLog: consoleLog);
  final saveImageController = SaveImageController(nativeBridge: bridge, consoleLog: consoleLog);
  final paymentController = PaymentController(nativeBridge: bridge, consoleLog: consoleLog);

  runApp(App(
    authController: authController,
    authDefaults: config.authConfig,
    shareController: shareController,
    saveImageController: saveImageController,
    paymentController: paymentController,
    consoleLog: consoleLog,
  ));
}
