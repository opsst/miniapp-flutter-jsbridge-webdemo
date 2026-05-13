# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter Web sample (`flutter_jsbridge_sample`) that calls a native JSBridge from Flutter Web running inside a native WebView (Android `window.JSBridge.*` or iOS `window.webkit.messageHandlers.*`). Normal browsers do not expose these objects — see README "Browser Testing Mock" for the JS snippet to paste into DevTools.

## Commands

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=AUTH_CLIENT_ID=your-client-id \
  --dart-define=AUTH_SCOPE=openid+offline+paotangid.citizen
flutter test                                    # all tests
flutter test test/widget_test.dart              # single test file
flutter analyze                                 # lint (uses analysis_options.yaml → flutter_lints)
flutter build web --dart-define=...             # production build
```

All bridge object/method/callback names are configurable via `--dart-define` (see README "Config" table). App source must not hardcode any of them.

## Architecture

Strict one-way layering — keep these boundaries when editing:

```
main.dart → app/ (UI) → features/{auth,share,save_image,payment}/ (controller + state) → bridge/ (JS interop) → config/ (--dart-define)
```

- **`config/`** — `AppConfig.fromEnvironment()` reads `--dart-define` values into `BridgeConfig` (JS object/method/callback names for all four bridge calls) and `AuthConfig` (clientId, scope; both have hardcoded defaults). Constructed once in `main.dart` and injected downward; nothing else reads `String.fromEnvironment` directly.
- **`bridge/js_interop_utils.dart`** — the only file allowed to touch raw JS-property access (via `dart:js_interop_unsafe`'s `getProperty`/`setProperty`). Exposes typed extensions (`getJSObject`, `getJSFunction`, `setJSObject`, `setJSFunction`) and a `lookupPath(window, [...])` helper. Use these everywhere instead of repeating null/`isA`/cast. **Do not redeclare `external getProperty`/`setProperty` here** — those don't bind at runtime; always import `dart:js_interop_unsafe`.
- **`bridge/native_bridge.dart`** — the only file that touches `window` and JS callable boilerplate. Hosts `initAuth`, `shareContent`, `saveImageToGallery`, and `openPayment`. Each method tries the Android path then the iOS path, and registers callbacks on `window[bridge]`. All return `BridgeResult` (`BridgeSuccess` | `BridgeFailure`). **Android contract differs per method**: `initAuth` passes positional string args (clientId, scope); `shareContent` passes a single JSON-string arg; `saveImageToGallery` and `openPayment` each pass a single string arg. The iOS dispatch is shared via `_postIos(Map)` since the contract is uniform there. Callback shapes also differ: `initAuth` registers success+error (`JSString` arg); `shareContent` registers success+error (`JSString?` packageName); `saveImageToGallery` registers success+error (`JSBoolean` success); `openPayment` registers **error only** — on success native reloads the WebView with the deeplink URL.
- **`features/auth/`** — `AuthController` depends on `NativeBridge` + `AuthConfig`, exposes `AuthState` (`idle | loading | success | failure`).
- **`features/share/`** — `ShareController` depends only on `NativeBridge` (per-call inputs come from UI), exposes `ShareState`. UI calls `controller.share(title, description, content, icon, type)`.
- **`features/save_image/`** — `SaveImageController` depends only on `NativeBridge`, exposes `SaveImageState`. UI calls `controller.save(base64Data)`. The native success callback returns a `bool` — when `false`, controller maps to `failure` state. A `sample_image.dart` file holds a default base64 used to seed the input field.
- **`features/payment/`** — `PaymentController` depends only on `NativeBridge`, exposes `PaymentState` (`idle | sending | failure` — no `success`, since native navigates away on success). UI calls `controller.openPayment(txnRefId)`.
- **`app/`** — Material UI only. No JS interop, no config reads. `HomePage` stacks `AuthSection` + `ShareSection` + `SaveImageSection` + `PaymentSection` in a single scrollable column. Each section lives in its own file.

When adding a new bridge call: extend `BridgeConfig` with new `--dart-define` keys, add the method to `NativeBridge` using the typed JS-interop helpers (Android-then-iOS fallthrough, returning `BridgeResult` — pick positional-args / JSON-string / single-string per spec, and register only the callbacks the spec defines), and expose state via a `ChangeNotifier` under `features/<name>/`. Add a `<name>_section.dart` under `app/` and stack it in `HomePage`. Do not call JS from UI or controllers.

## Native callback contract

Native code invokes these on the Flutter callback object (default `window.bridge`):
- Success: `window.bridge.initAuthCallback('AUTHORIZATION_CODE')`
- Error: `window.bridge.initAuthCallbackError('ERROR_CODE', 'ERROR_DESCRIPTION')`

Callback names are configurable — use `BridgeConfig` fields, never string literals.
