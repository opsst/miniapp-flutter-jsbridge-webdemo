import 'package:flutter/material.dart';

import '../features/auth/auth_controller.dart';
import '../features/payment/payment_controller.dart';
import '../features/save_image/save_image_controller.dart';
import '../features/share/share_controller.dart';
import 'auth_section.dart';
import 'payment_section.dart';
import 'save_image_section.dart';
import 'share_section.dart';

class App extends StatelessWidget {
  final AuthController authController;
  final ShareController shareController;
  final SaveImageController saveImageController;
  final PaymentController paymentController;

  const App({
    super.key,
    required this.authController,
    required this.shareController,
    required this.saveImageController,
    required this.paymentController,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter JSBridge Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomePage(
        authController: authController,
        shareController: shareController,
        saveImageController: saveImageController,
        paymentController: paymentController,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AuthController authController;
  final ShareController shareController;
  final SaveImageController saveImageController;
  final PaymentController paymentController;

  const HomePage({
    super.key,
    required this.authController,
    required this.shareController,
    required this.saveImageController,
    required this.paymentController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Web JSBridge')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthSection(controller: authController),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                ShareSection(controller: shareController),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                SaveImageSection(controller: saveImageController),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                PaymentSection(controller: paymentController),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
