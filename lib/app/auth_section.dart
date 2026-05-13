import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';

const _subtitle =
    'Calls Android window.JSBridge.initAuth or iOS window.webkit.messageHandlers observer.';

class AuthSection extends StatefulWidget {
  final AuthController controller;
  final AuthConfig defaults;

  const AuthSection({
    super.key,
    required this.controller,
    required this.defaults,
  });

  @override
  State<AuthSection> createState() => _AuthSectionState();
}

class _AuthSectionState extends State<AuthSection> {
  late final TextEditingController _clientId;
  late final TextEditingController _scope;

  @override
  void initState() {
    super.initState();
    _clientId = TextEditingController(text: widget.defaults.clientId);
    _scope = TextEditingController(text: widget.defaults.scope);
    _clientId.addListener(() => setState(() {}));
    _scope.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _clientId.dispose();
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final state = widget.controller.state;
        final isLoading = state.status == AuthStatus.loading;
        final canStart = !isLoading &&
            _clientId.text.trim().isNotEmpty &&
            _scope.text.trim().isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Native Auth Bridge', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(_subtitle),
            const SizedBox(height: 16),
            TextField(
              controller: _clientId,
              decoration: const InputDecoration(
                labelText: 'Client ID *',
                helperText: 'AUTH_CLIENT_ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _scope,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Scope *',
                helperText: 'AUTH_SCOPE — e.g. openid+offline+...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canStart
                  ? () => widget.controller.initAuth(
                        clientId: _clientId.text,
                        scope: _scope.text,
                      )
                  : null,
              child: Text(isLoading ? 'Starting...' : 'Start Init Auth'),
            ),
            const SizedBox(height: 16),
            _StatusCard(state: state),
          ],
        );
      },
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
