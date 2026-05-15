import 'package:flutter/material.dart';

import '../config/auth_config.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_state.dart';
import 'app_theme.dart';
import 'status_card.dart';

const _subtitle =
    'Calls Android window.JSBridge.initAuth or iOS webkit messageHandlers observer.';

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.key_rounded, size: 22, color: AppTheme.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Native auth bridge',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _subtitle,
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _clientId,
              decoration: const InputDecoration(
                labelText: 'Client ID *',
                helperText: 'AUTH_CLIENT_ID',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scope,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Scope *',
                helperText: 'AUTH_SCOPE — e.g. openid+offline+...',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canStart
                  ? () => widget.controller.initAuth(
                        clientId: _clientId.text,
                        scope: _scope.text,
                      )
                  : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.background),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(isLoading ? 'Starting...' : 'Start init auth'),
            ),
            const SizedBox(height: 20),
            StatusCard(
              type: _statusType(state.status),
              title: _titleFor(state.status),
              message: _messageFor(state),
            ),
          ],
        );
      },
    );
  }
}

StatusType _statusType(AuthStatus status) => switch (status) {
      AuthStatus.idle => StatusType.idle,
      AuthStatus.loading => StatusType.loading,
      AuthStatus.success => StatusType.success,
      AuthStatus.failure => StatusType.failure,
    };

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
