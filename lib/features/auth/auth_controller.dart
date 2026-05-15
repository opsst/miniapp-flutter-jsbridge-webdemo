import 'package:flutter/foundation.dart';

import '../../app/console_log.dart';
import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'auth_state.dart';

class AuthController extends ChangeNotifier {
  final NativeBridge _nativeBridge;
  final ConsoleLogService _log;

  AuthController({required NativeBridge nativeBridge, required ConsoleLogService consoleLog})
      : _nativeBridge = nativeBridge,
        _log = consoleLog;

  AuthState _state = const AuthState();
  AuthState get state => _state;

  Future<void> initAuth({required String clientId, required String scope}) async {
    _setState(const AuthState(status: AuthStatus.loading));

    _log.logRequest('initAuth', {'clientId': clientId, 'scope': scope});

    final result = await _nativeBridge.initAuth(
      clientId: clientId,
      scope: scope,
      onSuccess: (code) {
        _log.logCallback('initAuth', {'authorizationCode': code});
        _setState(AuthState(
          status: AuthStatus.success,
          authorizationCode: code,
        ));
      },
      onError: (code, description) {
        _log.logCallback('initAuth', {'errorCode': code, 'errorDescription': description}, isError: true);
        _setState(AuthState(
          status: AuthStatus.failure,
          errorMessage: '$code: $description',
        ));
      },
    );

    if (result is BridgeFailure<void>) {
      _log.logCallback('initAuth', {'errorCode': result.code, 'errorMessage': result.message}, isError: true);
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
