import 'package:flutter/foundation.dart';

import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'share_state.dart';

class ShareController extends ChangeNotifier {
  final NativeBridge _nativeBridge;

  ShareController({required NativeBridge nativeBridge}) : _nativeBridge = nativeBridge;

  ShareState _state = const ShareState();
  ShareState get state => _state;

  Future<void> share({
    String? title,
    String? description,
    required String content,
    String? icon,
    required String type,
  }) async {
    _setState(const ShareState(status: ShareStatus.loading));

    final result = await _nativeBridge.shareContent(
      title: title,
      description: description,
      content: content,
      icon: icon,
      type: type,
      onSuccess: (packageName) => _setState(ShareState(
        status: ShareStatus.success,
        packageName: packageName,
      )),
      onError: (code, description) => _setState(ShareState(
        status: ShareStatus.failure,
        errorMessage: '$code: $description',
      )),
    );

    if (result is BridgeFailure<void>) {
      _setState(ShareState(
        status: ShareStatus.failure,
        errorMessage: '${result.code}: ${result.message}',
      ));
    }
  }

  void _setState(ShareState value) {
    _state = value;
    notifyListeners();
  }
}
