import 'package:flutter/foundation.dart';

import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'save_image_state.dart';

class SaveImageController extends ChangeNotifier {
  final NativeBridge _nativeBridge;

  SaveImageController({required NativeBridge nativeBridge}) : _nativeBridge = nativeBridge;

  SaveImageState _state = const SaveImageState();
  SaveImageState get state => _state;

  Future<void> save(String base64Data) async {
    _setState(const SaveImageState(status: SaveImageStatus.loading));

    final result = await _nativeBridge.saveImageToGallery(
      data: base64Data,
      onSuccess: (success) => _setState(SaveImageState(
        status: success ? SaveImageStatus.success : SaveImageStatus.failure,
        success: success,
        errorMessage: success ? null : 'Native reported failure.',
      )),
      onError: (code, description) => _setState(SaveImageState(
        status: SaveImageStatus.failure,
        errorMessage: '$code: $description',
      )),
    );

    if (result is BridgeFailure<void>) {
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
