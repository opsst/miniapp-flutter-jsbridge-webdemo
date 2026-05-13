import 'package:flutter/material.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';

const _subtitle =
    'Calls Android window.JSBridge.initAuth or iOS window.webkit.messageHandlers observer.';

class AuthSection extends StatelessWidget {
  final AuthController controller;

  const AuthSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => _AuthBody(state: controller.state, onStart: controller.initAuth),
    );
  }
}

class _AuthBody extends StatelessWidget {
  final AuthState state;
  final VoidCallback onStart;

  const _AuthBody({required this.state, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final isLoading = state.status == AuthStatus.loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Native Auth Bridge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(_subtitle),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isLoading ? null : onStart,
          child: Text(isLoading ? 'Starting...' : 'Start Init Auth'),
        ),
        const SizedBox(height: 16),
        _StatusCard(state: state),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AuthState state;

  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titleFor(state.status), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(_messageFor(state)),
          ],
        ),
      ),
    );
  }
}

String _titleFor(AuthStatus status) => switch (status) {
      AuthStatus.idle => 'Idle',
      AuthStatus.loading => 'Waiting for native callback...',
      AuthStatus.success => 'Success',
      AuthStatus.failure => 'Failure',
    };

String _messageFor(AuthState state) => switch (state.status) {
      AuthStatus.idle => 'Tap the button to call native bridge.',
      AuthStatus.loading => 'Native should call window.bridge.initAuthCallback or initAuthCallbackError.',
      AuthStatus.success => state.authorizationCode ?? '-',
      AuthStatus.failure => state.errorMessage ?? '-',
    };
