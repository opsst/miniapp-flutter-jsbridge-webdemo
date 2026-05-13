import 'package:flutter/foundation.dart';

import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'payment_state.dart';

class PaymentController extends ChangeNotifier {
  final NativeBridge _nativeBridge;

  PaymentController({required NativeBridge nativeBridge}) : _nativeBridge = nativeBridge;

  PaymentState _state = const PaymentState();
  PaymentState get state => _state;

  Future<void> openPayment(String txnRefId) async {
    _setState(const PaymentState(status: PaymentStatus.sending));

    final result = await _nativeBridge.openPayment(
      txnRefId: txnRefId,
      onError: (code, description) => _setState(PaymentState(
        status: PaymentStatus.failure,
        errorMessage: '$code: $description',
      )),
    );

    if (result is BridgeFailure<void>) {
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
