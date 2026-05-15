import 'package:flutter/foundation.dart';

import '../../app/console_log.dart';
import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'save_image_state.dart';

class SaveImageController extends ChangeNotifier {
  final NativeBridge _nativeBridge;
  final ConsoleLogService _log;

  SaveImageController({required NativeBridge nativeBridge, required ConsoleLogService consoleLog})
      : _nativeBridge = nativeBridge,
        _log = consoleLog;

  SaveImageState _state = const SaveImageState();
  SaveImageState get state => _state;

  Future<void> save(String base64Data) async {
    _setState(const SaveImageState(status: SaveImageStatus.loading));

    _log.logRequest('saveImageToGallery', {'data': base64Data});

    final result = await _nativeBridge.saveImageToGallery(
      data: base64Data,
      onSuccess: (success) {
        _log.logCallback('saveImageToGallery', {'success': success.toString()});
        _setState(SaveImageState(
          status: success ? SaveImageStatus.success : SaveImageStatus.failure,
          success: success,
          errorMessage: success ? null : 'Native reported failure.',
        ));
      },
      onError: (code, description) {
        _log.logCallback('saveImageToGallery', {'errorCode': code, 'errorDescription': description}, isError: true);
        _setState(SaveImageState(
          status: SaveImageStatus.failure,
          errorMessage: '$code: $description',
        ));
      },
    );

    if (result is BridgeFailure<void>) {
      _log.logCallback('saveImageToGallery', {'errorCode': result.code, 'errorMessage': result.message}, isError: true);
      _setState(SaveImageState(
        status: SaveImageStatus.failure,
        errorMessage: '${result.code}: ${result.message}',
      ));
    }
  }

  void _setState(SaveImageState value) {
    _state = value;
    notifyListeners();
  }
}
