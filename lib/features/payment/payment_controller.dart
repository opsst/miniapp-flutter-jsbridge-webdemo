import 'package:flutter/foundation.dart';

import '../../app/console_log.dart';
import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'payment_state.dart';

class PaymentController extends ChangeNotifier {
  final NativeBridge _nativeBridge;
  final ConsoleLogService _log;

  PaymentController({required NativeBridge nativeBridge, required ConsoleLogService consoleLog})
      : _nativeBridge = nativeBridge,
        _log = consoleLog;

  PaymentState _state = const PaymentState();
  PaymentState get state => _state;

  Future<void> openPayment(String txnRefId) async {
    _setState(const PaymentState(status: PaymentStatus.sending));

    _log.logRequest('openPayment', {'txnRefId': txnRefId});

    final result = await _nativeBridge.openPayment(
      txnRefId: txnRefId,
      onError: (code, description) {
        _log.logCallback('openPayment', {'errorCode': code, 'errorDescription': description}, isError: true);
        _setState(PaymentState(
          status: PaymentStatus.failure,
          errorMessage: '$code: $description',
        ));
      },
    );

    if (result is BridgeFailure<void>) {
      _log.logCallback('openPayment', {'errorCode': result.code, 'errorMessage': result.message}, isError: true);
      _setState(PaymentState(
        status: PaymentStatus.failure,
        errorMessage: '${result.code}: ${result.message}',
      ));
    }
  }

  void _setState(PaymentState value) {
    _state = value;
    notifyListeners();
  }
}
