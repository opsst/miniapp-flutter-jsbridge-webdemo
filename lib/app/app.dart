import 'package:flutter/material.dart';

import '../features/auth/auth_controller.dart';
import '../features/share/share_controller.dart';
import 'auth_section.dart';
import 'share_section.dart';

class App extends StatelessWidget {
  final AuthController authController;
  final ShareController shareController;

  const App({
    super.key,
    required this.authController,
    required this.shareController,
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
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AuthController authController;
  final ShareController shareController;

  const HomePage({
    super.key,
    required this.authController,
    required this.shareController,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
