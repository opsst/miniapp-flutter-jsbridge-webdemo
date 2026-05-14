# 1. How Flutter Implements the JSBridge (Web ↔ Native App)

This document explains how `flutter_jsbridge_sample` (Flutter Web) talks to a native host (Android `WebView` or iOS `WKWebView`) using a JS bridge — and how the native host talks back.

> Audience: developers extending or integrating this Flutter Web miniapp.

---

## 1.1 The big picture

The Flutter Web app is loaded inside a **native WebView**. The WebView injects two host-specific JS surfaces into `window`:

| Platform | Surface Flutter calls TO | Shape |
|---|---|---|
| Android | `window.JSBridge.<methodName>(...)` | A JS object whose properties are functions exposed by the Android `@JavascriptInterface` |
| iOS | `window.webkit.messageHandlers.<handler>.postMessage(payload)` | A `WKScriptMessageHandler` registered against a WKWebView user content controller |

Native talks back to Flutter through a **single shared JS object** owned by Flutter:

```
window.bridge.<callbackName>(...args)
```

Flutter creates `window.bridge` lazily and registers callback functions on it before each call. Native invokes those functions when the work is done.

```
┌──────────────┐  call request   ┌──────────────────────────────────────┐
│ Flutter Web  │ ─────────────►  │ Android: window.JSBridge.<method>()  │
│  (Dart →     │                 │ iOS:     webkit.messageHandlers.post │
│   JS interop)│                 └──────────────────────────────────────┘
│              │                              │
│              │                              ▼
│              │                       Native code runs
│              │                              │
│              │  ◄──── invokes ──── window.bridge.<callbackName>(args)
└──────────────┘
```

---

## 1.2 Layering (one-way, top to bottom)

```
main.dart
   │
   ▼
app/                  ← Material UI only. No JS, no env reads.
   │
   ▼
features/<name>/      ← Controller (ChangeNotifier) + State.
   │                    Owns business logic, NOT JS.
   ▼
bridge/               ← The ONLY layer that touches window / JSObject.
   │
   ▼
config/               ← BridgeConfig + AuthConfig from --dart-define.
```

Source map:

| Folder | Purpose | Key files |
|---|---|---|
| `lib/config/` | `--dart-define` → typed config | `app_config.dart`, `bridge_config.dart`, `auth_config.dart` |
| `lib/bridge/` | JS interop, callable boilerplate | `js_interop_utils.dart`, `native_bridge.dart`, `bridge_result.dart` |
| `lib/features/<name>/` | Per-call controller + state | `*_controller.dart`, `*_state.dart` |
| `lib/app/` | Pure Material UI | `app.dart`, `<name>_section.dart` |
| `lib/main.dart` | Wires everything once | — |

**Rule:** UI never imports `bridge/`. Controllers never import `dart:js_interop*`. Only `bridge/` reads/writes `window`.

---

## 1.3 The config layer (`lib/config/`)

All bridge object/method/callback names are configurable through `--dart-define` so the same Dart binary can ship to different native hosts.

`BridgeConfig.fromEnvironment()` (`lib/config/bridge_config.dart:44`) reads keys with safe defaults:

| `--dart-define` key | Default | Used as |
|---|---|---|
| `JS_BRIDGE_OBJECT` | `JSBridge` | `window.<...>` (Android entry object) |
| `FLUTTER_CALLBACK_OBJECT` | `bridge` | `window.<...>` (where Flutter installs callbacks) |
| `IOS_MESSAGE_HANDLER` | `observer` | `window.webkit.messageHandlers.<...>` |
| `AUTH_METHOD_NAME` | `initAuth` | Android method name + `name` field in iOS payload |
| `AUTH_CALLBACK_NAME` | `initAuthCallback` | success callback registered on `window.bridge` |
| `AUTH_ERROR_CALLBACK_NAME` | `initAuthCallbackError` | error callback registered on `window.bridge` |
| `SHARE_METHOD_NAME` | `shareContent` | … |
| `SHARE_CALLBACK_NAME` | `shareContentCallback` | … |
| `SHARE_ERROR_CALLBACK_NAME` | `shareContentCallbackError` | … |
| `SAVE_IMAGE_METHOD_NAME` | `saveImageToGallery` | … |
| `SAVE_IMAGE_CALLBACK_NAME` | `saveImageToGalleryCallback` | … |
| `SAVE_IMAGE_ERROR_CALLBACK_NAME` | `saveImageToGalleryCallbackError` | … |
| `OPEN_PAYMENT_METHOD_NAME` | `openPayment` | … |
| `OPEN_PAYMENT_ERROR_CALLBACK_NAME` | `openPaymentCallbackError` | error only — no success callback |
| `AUTH_CLIENT_ID`, `AUTH_SCOPE` | (sample defaults) | runtime auth params |

`AppConfig.fromEnvironment()` (`lib/config/app_config.dart:13`) is constructed once in `main.dart:12` and injected downward. **Nothing else reads `String.fromEnvironment` directly.**

---

## 1.4 The JS interop helpers (`lib/bridge/js_interop_utils.dart`)

This is the only file allowed to do raw JS-property access. It uses `dart:js_interop` (modern, preferred) plus `dart:js_interop_unsafe`'s `getProperty` / `setProperty` for dynamic name lookups.

It exposes a small typed API used everywhere else:

```dart
extension JSObjectAccess on JSObject {
  JSObject?  getJSObject(String name);
  JSFunction? getJSFunction(String name);
  void        setJSObject(String name, JSObject value);
  void        setJSFunction(String name, JSFunction value);
}

JSObject? lookupPath(JSObject root, List<String> path); // e.g. ['webkit','messageHandlers','observer']
JSObject  createJsObject(Map<String, Object?> value);   // jsify a Dart map
```

> ⚠️ Do **not** redeclare `external getProperty` / `setProperty` here — those don't bind at runtime. Always import `dart:js_interop_unsafe`.

---

## 1.5 The bridge core (`lib/bridge/native_bridge.dart`)

`NativeBridge` is the only class that touches `window`. It owns four methods (one per native capability), and a few shared helpers.

### 1.5.1 The call pattern (every method follows this)

```dart
Future<BridgeResult<void>> someMethod({...args, required onSuccess, required onError}) async {
  _registerSomeCallbacks(onSuccess: onSuccess, onError: onError); // 1. install callbacks on window.bridge
  if (/* args invalid */) return BridgeFailure(code: 'INVALID_CONFIG', ...); // 2. validate
  if (_invokeAndroidSome(...)) return BridgeSuccess(null);                    // 3. try Android
  if (_postIos({...}))           return BridgeSuccess(null);                  // 4. try iOS
  return _bridgeNotFound('someMethod');                                       // 5. neither host present
}
```

Key invariants:
- **Callbacks are registered first**, before native is even called, so a fast native handler can't fire before we're listening.
- **Android then iOS** — there is no platform detection; the bridge tries Android, and if `window.JSBridge.<method>` isn't a function, falls through to iOS.
- **Every method returns `BridgeResult<void>`** — one of `BridgeSuccess(null)` or `BridgeFailure(code, message)` (`lib/bridge/bridge_result.dart`). Async results arrive via the registered callbacks; the `Future` only signals "the bridge hop succeeded".

### 1.5.2 The Android invocation (per method)

The Android contract is **not uniform across methods**. Each method packages its arguments differently:

| Method | Android call shape |
|---|---|
| `initAuth` | `window.JSBridge.initAuth(clientId, scope)` — **positional string args** |
| `shareContent` | `window.JSBridge.shareContent(jsonString)` — **single JSON-string arg** containing `{name, title?, description?, content, icon?, type}` |
| `saveImageToGallery` | `window.JSBridge.saveImageToGallery(base64Data)` — **single string arg** |
| `openPayment` | `window.JSBridge.openPayment(txnRefId)` — **single string arg** |

In Dart this looks like (see `_invokeAndroidShare` at `lib/bridge/native_bridge.dart:132`):

```dart
final bridge = window.getJSObject(config.jsBridgeObjectName);
final method = bridge?.getJSFunction(config.shareMethodName);
if (bridge == null || method == null) return false;

method.callAsFunction(bridge, jsonEncode(payload).toJS);
return true;
```

### 1.5.3 The iOS invocation (uniform across methods)

iOS uses a single shared helper — `_postIos(Map)` (`lib/bridge/native_bridge.dart:239`):

```dart
final handler     = lookupPath(window, ['webkit', 'messageHandlers', config.iosMessageHandlerName]);
final postMessage = handler?.getJSFunction('postMessage');
if (handler == null || postMessage == null) return false;

postMessage.callAsFunction(handler, createJsObject(payload));
return true;
```

Every iOS payload has the form `{name: '<methodName>', ...args}`. Native dispatches on `payload.name`.

### 1.5.4 Callback registration (per method)

Callbacks are installed on `window.<FLUTTER_CALLBACK_OBJECT>` (default `window.bridge`). The object is created lazily on first use by `_ensureCallbackObject()` (`native_bridge.dart:248`).

Each method registers exactly the callbacks it expects:

| Method | Callbacks registered (on `window.bridge`) | Argument shapes |
|---|---|---|
| `initAuth` | `initAuthCallback`, `initAuthCallbackError` | `(JSString code)` / `(JSString code, JSString description)` |
| `shareContent` | `shareContentCallback`, `shareContentCallbackError` | `(JSString? packageName)` / `(JSString code, JSString description)` |
| `saveImageToGallery` | `saveImageToGalleryCallback`, `saveImageToGalleryCallbackError` | `(JSBoolean success)` / `(JSString code, JSString description)` |
| `openPayment` | `openPaymentCallbackError` **only** | `(JSString code, JSString description)` — on success native reloads the WebView with the deeplink URL |

Registration is just `setJSFunction` with a `.toJS`'d closure, e.g. (`native_bridge.dart:53`):

```dart
callbacks.setJSFunction(
  config.authCallbackName,
  ((JSString code) => onSuccess(code.toDart)).toJS,
);
```

---

## 1.6 The feature layer (`lib/features/<name>/`)

Each feature has:
- a **state class** (`enum <Name>Status { idle, loading, success, failure }` + a value object)
- a **controller** (`extends ChangeNotifier`) with one public action method

The controller is the only place that knows how to map bridge results to UI state. It always:
1. Pushes a `loading` state.
2. Calls the bridge with `onSuccess` / `onError` lambdas that push `success` / `failure` state.
3. After `await`, if the bridge hop returned `BridgeFailure` (e.g. no native found), pushes `failure` with that code/message.

Example — `AuthController` (`lib/features/auth/auth_controller.dart:15`):

```dart
Future<void> initAuth({required String clientId, required String scope}) async {
  _setState(const AuthState(status: AuthStatus.loading));

  final result = await _nativeBridge.initAuth(
    clientId: clientId,
    scope: scope,
    onSuccess: (code) => _setState(AuthState(status: AuthStatus.success, authorizationCode: code)),
    onError:   (code, description) =>
        _setState(AuthState(status: AuthStatus.failure, errorMessage: '$code: $description')),
  );

  if (result is BridgeFailure<void>) {
    _setState(AuthState(status: AuthStatus.failure, errorMessage: '${result.code}: ${result.message}'));
  }
}
```

Per-feature state highlights:
- `AuthState` carries `authorizationCode`.
- `ShareState` carries `packageName` (nullable).
- `SaveImageState` carries `bool success`. Native success callback returns `bool` — when `false`, controller maps to `failure`.
- `PaymentState` has **no `success` value** — only `idle | sending | failure`, because on success native navigates away.

---

## 1.7 The UI layer (`lib/app/`)

`HomePage` (`lib/app/app.dart:49`) stacks four sections — `AuthSection`, `ShareSection`, `SaveImageSection`, `PaymentSection` — in a `SingleChildScrollView`. Each section:
- Holds its `TextEditingController`s for inputs.
- Wraps an `AnimatedBuilder(animation: controller, ...)` to rebuild when the controller `notifyListeners()`.
- Renders a button that calls the controller's action method.
- Renders a `_StatusCard` that switches on the state's `status` enum.

The UI is intentionally dumb: it never calls JS and never reads env vars.

---

## 1.8 Dependency injection (`lib/main.dart`)

```dart
void main() {
  const config = AppConfig.fromEnvironment();
  final bridge = NativeBridge(config.bridgeConfig);

  final authController       = AuthController(nativeBridge: bridge);
  final shareController      = ShareController(nativeBridge: bridge);
  final saveImageController  = SaveImageController(nativeBridge: bridge);
  final paymentController    = PaymentController(nativeBridge: bridge);

  runApp(App(
    authController: authController,
    authDefaults: config.authConfig,
    shareController: shareController,
    saveImageController: saveImageController,
    paymentController: paymentController,
  ));
}
```

One `BridgeConfig`, one `NativeBridge`, four controllers. Anything new should follow the same shape.

---

## 1.9 End-to-end timeline of a single call (initAuth example)

1. User types Client ID + Scope, taps **Start Init Auth** in `AuthSection`.
2. `AuthSection` calls `authController.initAuth(clientId, scope)`.
3. `AuthController` sets state `loading`, awaits `nativeBridge.initAuth(...)`.
4. `NativeBridge`:
   1. Ensures `window.bridge` exists, installs `initAuthCallback` and `initAuthCallbackError` on it.
   2. Tries `window.JSBridge.initAuth(clientId, scope)` (Android). If found and callable, returns `BridgeSuccess`.
   3. Else tries `window.webkit.messageHandlers.observer.postMessage({name:'initAuth', clientId, scope})` (iOS). Returns `BridgeSuccess`.
   4. Else returns `BridgeFailure('BRIDGE_NOT_FOUND', ...)`.
5. Native authenticates, then calls **either**:
   - `window.bridge.initAuthCallback('AUTHORIZATION_CODE')` → controller pushes `success` state.
   - `window.bridge.initAuthCallbackError('CODE', 'DESC')` → controller pushes `failure` state.
6. `_StatusCard` rebuilds via `AnimatedBuilder`.

---

## 1.10 Browser testing without a real native host

Normal Chrome doesn't have `window.JSBridge` or `webkit.messageHandlers`. To test in DevTools, paste a mock **before** clicking the button:

```js
// Success mock
window.JSBridge = {
  initAuth: function(clientId, scope) {
    console.log('mock initAuth', clientId, scope);
    setTimeout(() => window.bridge.initAuthCallback('mock-auth-code-123'), 500);
  }
};

// Error mock
window.JSBridge = {
  initAuth: function(clientId, scope) {
    setTimeout(() => window.bridge.initAuthCallbackError('AUTH_FAILED', 'Mock auth failed'), 500);
  }
};
```

Equivalent mocks for `shareContent`, `saveImageToGallery`, and `openPayment` are in `README.md` under **Browser Testing Mock**.

---

## 1.11 Why this design

- **UI ↔ JS isolation.** UI knows about `Controller` only; controllers know about `NativeBridge` only; only `NativeBridge` touches `window`. Renaming a JS callback or switching from `JSBridge` to `MyBridge` is a one-file change in `bridge_config.dart` (or even just a `--dart-define`).
- **Configurable everything.** Different native hosts (different brands / build flavors) can reuse the same Dart binary by overriding `--dart-define`s.
- **Typed JS interop.** `js_interop_utils.dart` removes repeated null/`isA`/cast boilerplate so feature-specific code in `native_bridge.dart` stays readable.
- **`BridgeResult<T>` instead of throwing.** Lets controllers handle "no native present" identically to "callback returned error".
