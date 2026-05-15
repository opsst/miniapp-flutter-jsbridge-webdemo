import 'package:flutter/foundation.dart';

import '../../app/console_log.dart';
import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'share_state.dart';

class ShareController extends ChangeNotifier {
  final NativeBridge _nativeBridge;
  final ConsoleLogService _log;

  ShareController({required NativeBridge nativeBridge, required ConsoleLogService consoleLog})
      : _nativeBridge = nativeBridge,
        _log = consoleLog;

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

    _log.logRequest('shareContent', {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'content': content,
      if (icon != null) 'icon': icon,
      'type': type,
    });

    final result = await _nativeBridge.shareContent(
      title: title,
      description: description,
      content: content,
      icon: icon,
      type: type,
      onSuccess: (packageName) {
        _log.logCallback('shareContent', {'packageName': packageName ?? '-'});
        _setState(ShareState(
          status: ShareStatus.success,
          packageName: packageName,
        ));
      },
      onError: (code, description) {
        _log.logCallback('shareContent', {'errorCode': code, 'errorDescription': description}, isError: true);
        _setState(ShareState(
          status: ShareStatus.failure,
          errorMessage: '$code: $description',
        ));
      },
    );

    if (result is BridgeFailure<void>) {
      _log.logCallback('shareContent', {'errorCode': result.code, 'errorMessage': result.message}, isError: true);
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
