class BridgeConfig {
  // Names of JS objects on `window`.
  final String jsBridgeObjectName;
  final String flutterCallbackObjectName;
  final String iosMessageHandlerName;

  // Names of the auth method and its callbacks.
  final String authMethodName;
  final String authCallbackName;
  final String authErrorCallbackName;

  // Names of the share method and its callbacks.
  final String shareMethodName;
  final String shareCallbackName;
  final String shareErrorCallbackName;

  // Names of the save-image-to-gallery method and its callbacks.
  final String saveImageMethodName;
  final String saveImageCallbackName;
  final String saveImageErrorCallbackName;

  // Names of the open-payment method and its error callback. (No success
  // callback — native reloads the WebView on success.)
  final String openPaymentMethodName;
  final String openPaymentErrorCallbackName;

  const BridgeConfig({
    required this.jsBridgeObjectName,
    required this.flutterCallbackObjectName,
    required this.iosMessageHandlerName,
    required this.authMethodName,
    required this.authCallbackName,
    required this.authErrorCallbackName,
    required this.shareMethodName,
    required this.shareCallbackName,
    required this.shareErrorCallbackName,
    required this.saveImageMethodName,
    required this.saveImageCallbackName,
    required this.saveImageErrorCallbackName,
    required this.openPaymentMethodName,
    required this.openPaymentErrorCallbackName,
  });

  const BridgeConfig.fromEnvironment()
      : jsBridgeObjectName = const String.fromEnvironment(
          'JS_BRIDGE_OBJECT',
          defaultValue: 'JSBridge',
        ),
        flutterCallbackObjectName = const String.fromEnvironment(
          'FLUTTER_CALLBACK_OBJECT',
          defaultValue: 'bridge',
        ),
        iosMessageHandlerName = const String.fromEnvironment(
          'IOS_MESSAGE_HANDLER',
          defaultValue: 'observer',
        ),
        authMethodName = const String.fromEnvironment(
          'AUTH_METHOD_NAME',
          defaultValue: 'initAuth',
        ),
        authCallbackName = const String.fromEnvironment(
          'AUTH_CALLBACK_NAME',
          defaultValue: 'initAuthCallback',
        ),
        authErrorCallbackName = const String.fromEnvironment(
          'AUTH_ERROR_CALLBACK_NAME',
          defaultValue: 'initAuthCallbackError',
        ),
        shareMethodName = const String.fromEnvironment(
          'SHARE_METHOD_NAME',
          defaultValue: 'shareContent',
        ),
        shareCallbackName = const String.fromEnvironment(
          'SHARE_CALLBACK_NAME',
          defaultValue: 'shareContentCallback',
        ),
        shareErrorCallbackName = const String.fromEnvironment(
          'SHARE_ERROR_CALLBACK_NAME',
          defaultValue: 'shareContentCallbackError',
        ),
        saveImageMethodName = const String.fromEnvironment(
          'SAVE_IMAGE_METHOD_NAME',
          defaultValue: 'saveImageToGallery',
        ),
        saveImageCallbackName = const String.fromEnvironment(
          'SAVE_IMAGE_CALLBACK_NAME',
          defaultValue: 'saveImageToGalleryCallback',
        ),
        saveImageErrorCallbackName = const String.fromEnvironment(
          'SAVE_IMAGE_ERROR_CALLBACK_NAME',
          defaultValue: 'saveImageToGalleryCallbackError',
        ),
        openPaymentMethodName = const String.fromEnvironment(
          'OPEN_PAYMENT_METHOD_NAME',
          defaultValue: 'openPayment',
        ),
        openPaymentErrorCallbackName = const String.fromEnvironment(
          'OPEN_PAYMENT_ERROR_CALLBACK_NAME',
          defaultValue: 'openPaymentCallbackError',
        );
}
