import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_jsbridge_sample/app/app.dart';
import 'package:flutter_jsbridge_sample/bridge/bridge_result.dart';
import 'package:flutter_jsbridge_sample/bridge/native_bridge.dart';
import 'package:flutter_jsbridge_sample/config/auth_config.dart';
import 'package:flutter_jsbridge_sample/config/bridge_config.dart';
import 'package:flutter_jsbridge_sample/features/auth/auth_controller.dart';
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
}

void main() {
  testWidgets('renders auth and share sections', (tester) async {
    final bridge = _StubNativeBridge();
    final auth = AuthController(
      nativeBridge: bridge,
      authConfig: const AuthConfig(clientId: 'demo', scope: 'demo'),
    );
    final share = ShareController(nativeBridge: bridge);

    await tester.pumpWidget(App(authController: auth, shareController: share));

    expect(find.text('Native Auth Bridge'), findsOneWidget);
    expect(find.text('Start Init Auth'), findsOneWidget);

    expect(find.text('Share Content'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('TEXT'), findsOneWidget);
    expect(find.text('IMAGE'), findsOneWidget);
  });
}
