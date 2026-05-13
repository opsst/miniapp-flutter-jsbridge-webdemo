import 'dart:convert';
import 'dart:js_interop';

import '../config/bridge_config.dart';
import 'bridge_result.dart';
import 'js_interop_utils.dart';

typedef AuthSuccessCallback = void Function(String authorizationCode);
typedef AuthErrorCallback = void Function(String errorCode, String errorDescription);

typedef ShareSuccessCallback = void Function(String? packageName);
typedef ShareErrorCallback = void Function(String errorCode, String errorDescription);

class NativeBridge {
  final BridgeConfig config;

  NativeBridge(this.config);

  // ───────── initAuth ─────────

  Future<BridgeResult<void>> initAuth({
    required String clientId,
    required String scope,
    required AuthSuccessCallback onSuccess,
    required AuthErrorCallback onError,
  }) async {
    _registerAuthCallbacks(onSuccess: onSuccess, onError: onError);

    if (clientId.trim().isEmpty || scope.trim().isEmpty) {
      return const BridgeFailure(
        code: 'INVALID_CONFIG',
        message: 'clientId and scope are required. Pass them with --dart-define.',
      );
    }

    if (_invokeAndroidAuth(clientId: clientId, scope: scope)) return const BridgeSuccess(null);
    if (_invokeIosAuth(clientId: clientId, scope: scope)) return const BridgeSuccess(null);

    return _bridgeNotFound('initAuth');
  }

  void _registerAuthCallbacks({
    required AuthSuccessCallback onSuccess,
    required AuthErrorCallback onError,
  }) {
    final callbacks = _ensureCallbackObject();

    callbacks.setJSFunction(
      config.authCallbackName,
      ((JSString code) => onSuccess(code.toDart)).toJS,
    );
    callbacks.setJSFunction(
      config.authErrorCallbackName,
      ((JSString code, JSString description) => onError(code.toDart, description.toDart)).toJS,
    );
  }

  bool _invokeAndroidAuth({required String clientId, required String scope}) {
    final bridge = window.getJSObject(config.jsBridgeObjectName);
    final method = bridge?.getJSFunction(config.authMethodName);
    if (bridge == null || method == null) return false;

    method.callAsFunction(bridge, clientId.toJS, scope.toJS);
    return true;
  }

  bool _invokeIosAuth({required String clientId, required String scope}) {
    return _postIos({
      'name': config.authMethodName,
      'clientId': clientId,
      'scope': scope,
    });
  }

  // ───────── shareContent ─────────

  Future<BridgeResult<void>> shareContent({
    String? title,
    String? description,
    required String content,
    String? icon,
    required String type,
    required ShareSuccessCallback onSuccess,
    required ShareErrorCallback onError,
  }) async {
    _registerShareCallbacks(onSuccess: onSuccess, onError: onError);

    if (content.trim().isEmpty || type.trim().isEmpty) {
      return const BridgeFailure(
        code: 'INVALID_CONFIG',
        message: 'content and type are required.',
      );
    }

    final payload = <String, Object?>{
      'name': config.shareMethodName,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'content': content,
      if (icon != null) 'icon': icon,
      'type': type,
    };

    if (_invokeAndroidShare(payload)) return const BridgeSuccess(null);
    if (_postIos(payload)) return const BridgeSuccess(null);

    return _bridgeNotFound('shareContent');
  }

  void _registerShareCallbacks({
    required ShareSuccessCallback onSuccess,
    required ShareErrorCallback onError,
  }) {
    final callbacks = _ensureCallbackObject();

    callbacks.setJSFunction(
      config.shareCallbackName,
      ((JSString? packageName) => onSuccess(packageName?.toDart)).toJS,
    );
    callbacks.setJSFunction(
      config.shareErrorCallbackName,
      ((JSString code, JSString description) => onError(code.toDart, description.toDart)).toJS,
    );
  }

  /// Android contract: a single JSON-string argument.
  bool _invokeAndroidShare(Map<String, Object?> payload) {
    final bridge = window.getJSObject(config.jsBridgeObjectName);
    final method = bridge?.getJSFunction(config.shareMethodName);
    if (bridge == null || method == null) return false;

    method.callAsFunction(bridge, jsonEncode(payload).toJS);
    return true;
  }

  // ───────── shared helpers ─────────

  /// iOS contract: post the payload object to the configured message handler.
  bool _postIos(Map<String, Object?> payload) {
    final handler = lookupPath(window, ['webkit', 'messageHandlers', config.iosMessageHandlerName]);
    final postMessage = handler?.getJSFunction('postMessage');
    if (handler == null || postMessage == null) return false;

    postMessage.callAsFunction(handler, createJsObject(payload));
    return true;
  }

  JSObject _ensureCallbackObject() {
    final existing = window.getJSObject(config.flutterCallbackObjectName);
    if (existing != null) return existing;

    final created = createJsObject({});
    window.setJSObject(config.flutterCallbackObjectName, created);
    return created;
  }

  BridgeFailure<void> _bridgeNotFound(String method) {
    print('$method: No supported native bridge found.');
    return const BridgeFailure(
      code: 'BRIDGE_NOT_FOUND',
      message: 'No JSBridge or iOS webkit message handler found.',
    );
  }
}
