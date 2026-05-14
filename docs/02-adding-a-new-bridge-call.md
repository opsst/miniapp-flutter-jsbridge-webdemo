# 2. How to Add a New JSBridge Call

This is the recipe for adding a new native capability — say, `getDeviceInfo` — to this Flutter Web miniapp. Follow it in order; the layering is strict.

> Read [`01-jsbridge-architecture.md`](./01-jsbridge-architecture.md) first if you haven't.

---

## 2.1 Before you start: agree on the contract with native

You need three things from the native team:

1. **The Android call shape.** Pick one of:
   - **Positional string args** — `window.JSBridge.foo(arg1, arg2, ...)` (used by `initAuth`).
   - **Single JSON-string arg** — `window.JSBridge.foo(JSON.stringify({...}))` (used by `shareContent`). Use this when the payload is structured / has optional fields.
   - **Single string arg** — `window.JSBridge.foo(value)` (used by `saveImageToGallery`, `openPayment`). Use this when there's only one value.
2. **The iOS payload shape.** iOS is uniform — always `webkit.messageHandlers.<handler>.postMessage({name:'<methodName>', ...args})`. Just decide field names.
3. **The callback shape.** For each, decide:
   - Success callback name + argument types (or **no success callback** if native navigates away on success — see `openPayment`).
   - Error callback name + argument types (almost always `(code, description)`).

Document these in the README under **Android Contract**, **iOS Contract**, and per-method **Callbacks** sections.

---

## 2.2 Step-by-step checklist

The example below adds a hypothetical `getDeviceInfo` call:
- Returns `{deviceId, osVersion}` via success callback.
- Android: `window.JSBridge.getDeviceInfo(jsonString)` (single JSON-string arg).
- iOS: `webkit.messageHandlers.observer.postMessage({name: 'getDeviceInfo', requestId})`.
- Success callback: `window.bridge.getDeviceInfoCallback(deviceId, osVersion)`.
- Error callback: `window.bridge.getDeviceInfoCallbackError(code, description)`.

### Step 1 — Add config keys (`lib/config/bridge_config.dart`)

Add three fields (method + 2 callback names) and read them with safe defaults:

```dart
final String getDeviceInfoMethodName;
final String getDeviceInfoCallbackName;
final String getDeviceInfoErrorCallbackName;
```

In the constructor and `fromEnvironment()`:

```dart
required this.getDeviceInfoMethodName,
required this.getDeviceInfoCallbackName,
required this.getDeviceInfoErrorCallbackName,
```

```dart
getDeviceInfoMethodName = const String.fromEnvironment(
  'GET_DEVICE_INFO_METHOD_NAME',
  defaultValue: 'getDeviceInfo',
),
getDeviceInfoCallbackName = const String.fromEnvironment(
  'GET_DEVICE_INFO_CALLBACK_NAME',
  defaultValue: 'getDeviceInfoCallback',
),
getDeviceInfoErrorCallbackName = const String.fromEnvironment(
  'GET_DEVICE_INFO_ERROR_CALLBACK_NAME',
  defaultValue: 'getDeviceInfoCallbackError',
),
```

> Do **not** add an env key for "is this method available" — the bridge already detects host presence at runtime.

### Step 2 — Add the method to `NativeBridge` (`lib/bridge/native_bridge.dart`)

Add typedefs at the top:

```dart
typedef DeviceInfoSuccessCallback = void Function(String deviceId, String osVersion);
typedef DeviceInfoErrorCallback   = void Function(String errorCode, String errorDescription);
```

Add a public method following the **call pattern** from §1.5.1:

```dart
Future<BridgeResult<void>> getDeviceInfo({
  required String requestId,
  required DeviceInfoSuccessCallback onSuccess,
  required DeviceInfoErrorCallback onError,
}) async {
  _registerDeviceInfoCallbacks(onSuccess: onSuccess, onError: onError);

  if (requestId.trim().isEmpty) {
    return const BridgeFailure(
      code: 'INVALID_CONFIG',
      message: 'requestId is required.',
    );
  }

  final payload = <String, Object?>{
    'name': config.getDeviceInfoMethodName,
    'requestId': requestId,
  };

  if (_invokeAndroidGetDeviceInfo(payload)) return const BridgeSuccess(null);
  if (_postIos(payload)) return const BridgeSuccess(null);

  return _bridgeNotFound('getDeviceInfo');
}
```

Register the callbacks:

```dart
void _registerDeviceInfoCallbacks({
  required DeviceInfoSuccessCallback onSuccess,
  required DeviceInfoErrorCallback onError,
}) {
  final callbacks = _ensureCallbackObject();

  callbacks.setJSFunction(
    config.getDeviceInfoCallbackName,
    ((JSString deviceId, JSString osVersion) =>
        onSuccess(deviceId.toDart, osVersion.toDart)).toJS,
  );
  callbacks.setJSFunction(
    config.getDeviceInfoErrorCallbackName,
    ((JSString code, JSString description) =>
        onError(code.toDart, description.toDart)).toJS,
  );
}
```

Add the Android invoker (mirror `_invokeAndroidShare`):

```dart
/// Android contract: a single JSON-string argument.
bool _invokeAndroidGetDeviceInfo(Map<String, Object?> payload) {
  final bridge = window.getJSObject(config.jsBridgeObjectName);
  final method = bridge?.getJSFunction(config.getDeviceInfoMethodName);
  if (bridge == null || method == null) return false;

  method.callAsFunction(bridge, jsonEncode(payload).toJS);
  return true;
}
```

> **Important:** pick the Android variant that matches the contract you agreed in §2.1:
> - Positional args → mirror `_invokeAndroidAuth` (pass each arg as `.toJS`).
> - JSON string → mirror `_invokeAndroidShare` (pass `jsonEncode(payload).toJS`).
> - Single string → mirror `_invokeAndroidSaveImage` / `_invokeAndroidOpenPayment` (pass the lone string `.toJS`).
>
> Do **not** invent a fourth variant. If native asks for it, push back or reuse JSON-string.

iOS uses the shared `_postIos(payload)` — no new helper needed unless you have a one-off shape.

### Step 3 — Define state (`lib/features/device_info/device_info_state.dart`)

```dart
enum DeviceInfoStatus { idle, loading, success, failure }

class DeviceInfoState {
  final DeviceInfoStatus status;
  final String? deviceId;
  final String? osVersion;
  final String? errorMessage;

  const DeviceInfoState({
    this.status = DeviceInfoStatus.idle,
    this.deviceId,
    this.osVersion,
    this.errorMessage,
  });
}
```

> If your method has **no success callback** (native navigates away), drop `success` from the enum — see `PaymentState`.
> If success returns a `bool`, map `false` to `failure` like `SaveImageController` does.

### Step 4 — Define the controller (`lib/features/device_info/device_info_controller.dart`)

```dart
import 'package:flutter/foundation.dart';

import '../../bridge/bridge_result.dart';
import '../../bridge/native_bridge.dart';
import 'device_info_state.dart';

class DeviceInfoController extends ChangeNotifier {
  final NativeBridge _nativeBridge;

  DeviceInfoController({required NativeBridge nativeBridge})
      : _nativeBridge = nativeBridge;

  DeviceInfoState _state = const DeviceInfoState();
  DeviceInfoState get state => _state;

  Future<void> fetch(String requestId) async {
    _setState(const DeviceInfoState(status: DeviceInfoStatus.loading));

    final result = await _nativeBridge.getDeviceInfo(
      requestId: requestId,
      onSuccess: (deviceId, osVersion) => _setState(DeviceInfoState(
        status: DeviceInfoStatus.success,
        deviceId: deviceId,
        osVersion: osVersion,
      )),
      onError: (code, description) => _setState(DeviceInfoState(
        status: DeviceInfoStatus.failure,
        errorMessage: '$code: $description',
      )),
    );

    if (result is BridgeFailure<void>) {
      _setState(DeviceInfoState(
        status: DeviceInfoStatus.failure,
        errorMessage: '${result.code}: ${result.message}',
      ));
    }
  }

  void _setState(DeviceInfoState value) {
    _state = value;
    notifyListeners();
  }
}
```

The shape — `loading → bridge call → onSuccess/onError lambdas → handle BridgeFailure post-await` — is identical to every other controller. Don't deviate.

### Step 5 — Add the UI section (`lib/app/device_info_section.dart`)

Mirror the structure of `auth_section.dart`:
- `StatefulWidget` holding `TextEditingController`(s) for inputs.
- Wrap the body in `AnimatedBuilder(animation: widget.controller, builder: ...)`.
- Render a `FilledButton` whose `onPressed` calls the controller's action.
- Render a `_StatusCard` with a `switch` on the state's status enum.

Then stack it in `HomePage` (`lib/app/app.dart:74`) between two `Divider`s, just like the others:

```dart
const SizedBox(height: 32),
const Divider(),
const SizedBox(height: 32),
DeviceInfoSection(controller: deviceInfoController),
```

### Step 6 — Wire it up in `main.dart`

```dart
final deviceInfoController = DeviceInfoController(nativeBridge: bridge);

runApp(App(
  // ...existing controllers...
  deviceInfoController: deviceInfoController,
));
```

Add the field/parameter to `App` and `HomePage` constructors (`lib/app/app.dart`) and forward it down.

### Step 7 — Update the README contract tables

Append rows to:
- **Config** table — your three new `--dart-define` keys.
- **Android Contract** code block — the JS call shape.
- **iOS Contract** code block — the postMessage payload.
- A new section listing your callback signatures + error codes.
- A new **Browser Testing Mock** snippet so devs can test without native (see template below).

### Step 8 — Add a browser mock

Paste-ready DevTools snippet (success + error variants). Match the style of existing mocks in README:

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.getDeviceInfo = function(jsonString) {
  console.log('mock getDeviceInfo', JSON.parse(jsonString));
  setTimeout(() => {
    window.bridge.getDeviceInfoCallback('mock-device-id', '17.4.1');
  }, 500);
};
```

```js
// Error variant
window.JSBridge = window.JSBridge || {};
window.JSBridge.getDeviceInfo = function(jsonString) {
  setTimeout(() => {
    window.bridge.getDeviceInfoCallbackError('MAW9999', 'Mock failure');
  }, 500);
};
```

### Step 9 — Verify

```bash
flutter pub get
flutter analyze                        # must be clean
flutter test                           # existing tests should still pass
flutter run -d chrome                  # then paste the mock, click your button, watch the status card
```

Then verify on a real native host (Android emulator + iOS simulator) before merging.

---

## 2.3 Cheat sheet — what file changes for what

| Adding… | Touch these files |
|---|---|
| A new bridge method | `lib/config/bridge_config.dart` (3 keys), `lib/bridge/native_bridge.dart` (typedefs + method + Android invoker + callback registrar) |
| A new feature | `lib/features/<name>/<name>_state.dart`, `lib/features/<name>/<name>_controller.dart` |
| A new screen section | `lib/app/<name>_section.dart`, then add to `HomePage` in `lib/app/app.dart` |
| Wiring | `lib/main.dart`, plus `App` / `HomePage` constructor params in `lib/app/app.dart` |
| Docs | `README.md` (Config table, Android Contract, iOS Contract, Callbacks, Browser Testing Mock) |

---

## 2.4 Common pitfalls

- **Calling JS from a controller or UI.** Don't. Only `lib/bridge/native_bridge.dart` may touch `window`.
- **Hardcoding bridge / method / callback names** anywhere outside `BridgeConfig`. Always read them from `config`.
- **Reading `String.fromEnvironment` outside `lib/config/`.** Wire env values once at construction time.
- **Redeclaring `external getProperty`/`setProperty`** in `js_interop_utils.dart`. They won't bind at runtime — import `dart:js_interop_unsafe` instead.
- **Registering callbacks after the native call.** Register first; native handlers can be synchronous.
- **Inventing a new Android arg shape.** Stick to one of the three documented patterns (positional / JSON-string / single-string).
- **Forgetting the `BridgeFailure` post-await branch in the controller.** Without it, "no native host" is silently swallowed.
- **Adding a success state for a navigation-on-success method.** Match the pattern in `PaymentState` (no `success` value).
- **Changing the iOS dispatch shape.** All iOS payloads must include `name: '<methodName>'` so native can route. Reuse `_postIos`.

---

## 2.5 Worked references

When in doubt, copy from the closest existing analog:

| Your method's Android shape | Use this as a template |
|---|---|
| Positional args | `_invokeAndroidAuth` (`lib/bridge/native_bridge.dart:63`) and `initAuth` (`:26`) |
| Single JSON-string arg | `_invokeAndroidShare` (`:132`) and `shareContent` (`:82`) |
| Single string arg | `_invokeAndroidSaveImage` (`:182`) / `_invokeAndroidOpenPayment` (`:227`) |
| Success callback returns `bool` | `SaveImageController.save` (`lib/features/save_image/save_image_controller.dart:15`) |
| No success callback (native navigates) | `openPayment` (`lib/bridge/native_bridge.dart:196`) and `PaymentState` |
