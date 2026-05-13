import 'package:flutter/foundation.dart';

import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import '../../config/auth_config.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  final NativeBridge _nativeBridge;
  final AuthConfig _authConfig;

  AuthController({
    required NativeBridge nativeBridge,
    required AuthConfig authConfig,
  })  : _nativeBridge = nativeBridge,
        _authConfig = authConfig;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  Future<void> initAuth() async {
    _setState(const AuthState(status: AuthStatus.loading));

    final result = await _nativeBridge.initAuth(
      clientId: _authConfig.clientId,
      scope: _authConfig.scope,
      onSuccess: (code) => _setState(AuthState(
        status: AuthStatus.success,
        authorizationCode: code,
      )),
      onError: (code, description) => _setState(AuthState(
        status: AuthStatus.failure,
        errorMessage: '$code: $description',
      )),
    );

    if (result is BridgeFailure<void>) {
      _setState(AuthState(
        status: AuthStatus.failure,
        errorMessage: '${result.code}: ${result.message}',
      ));
    }
  }

  void _setState(AuthState value) {
    _state = value;
    notifyListeners();
  }
}
