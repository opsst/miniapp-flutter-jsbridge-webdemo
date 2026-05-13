import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_jsbridge_sample/app/app.dart';
import 'package:flutter_jsbridge_sample/bridge/bridge_result.dart';
import 'package:flutter_jsbridge_sample/bridge/native_bridge.dart';
import 'package:flutter_jsbridge_sample/config/auth_config.dart';
import 'package:flutter_jsbridge_sample/config/bridge_config.dart';
import 'package:flutter_jsbridge_sample/features/auth/auth_controller.dart';
import 'package:flutter_jsbridge_sample/features/payment/payment_controller.dart';
import 'package:flutter_jsbridge_sample/features/save_image/save_image_controller.dart';
import 'package:flutter_jsbridge_sample/features/share/share_controller.dart';

class _StubNativeBridge extends NativeBridge {
  _StubNativeBridge() : super(const BridgeConfig.fromEnvironment());

  @override
  Future<BridgeResult<void>> initAuth({
    required String clientId,
    required String scope,
    required AuthSuccessCallback onSuccess,
    required AuthErrorCallback onError,
  }) async {
    return const BridgeSuccess(null);
  }

  @override
  Future<BridgeResult<void>> shareContent({
    String? title,
    String? description,
    required String content,
    String? icon,
    required String type,
    required ShareSuccessCallback onSuccess,
    required ShareErrorCallback onError,
  }) async {
    return const BridgeSuccess(null);
  }

  @override
  Future<BridgeResult<void>> saveImageToGallery({
    required String data,
    required SaveImageSuccessCallback onSuccess,
    required SaveImageErrorCallback onError,
  }) async {
    return const BridgeSuccess(null);
  }

  @override
  Future<BridgeResult<void>> openPayment({
    required String txnRefId,
    required PaymentErrorCallback onError,
  }) async {
    return const BridgeSuccess(null);
  }
}

void main() {
  testWidgets('renders auth, share, save-image and payment sections', (tester) async {
    final bridge = _StubNativeBridge();
    final auth = AuthController(nativeBridge: bridge);
    final share = ShareController(nativeBridge: bridge);
    final saveImage = SaveImageController(nativeBridge: bridge);
    final payment = PaymentController(nativeBridge: bridge);

    await tester.pumpWidget(App(
      authController: auth,
      authDefaults: const AuthConfig(clientId: 'demo', scope: 'demo'),
      shareController: share,
      saveImageController: saveImage,
      paymentController: payment,
    ));

    expect(find.text('Native Auth Bridge'), findsOneWidget);
    expect(find.text('Share Content'), findsOneWidget);
    expect(find.text('Save Image to Gallery'), findsOneWidget);
    expect(find.text('Open Payment'), findsAtLeastNWidgets(1));
  });
}
