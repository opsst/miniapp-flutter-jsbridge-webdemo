# Flutter Web JSBridge Sample

A small Flutter Web sample for calling a native JSBridge from Flutter Web.

## Flow

```text
Flutter Web
  -> NativeBridge.initAuth()
  -> Android: window.JSBridge.initAuth(clientId, scope)
  -> iOS: window.webkit.messageHandlers.<handler>.postMessage(payload)
  -> Native callback: window.bridge.initAuthCallback(code)
  -> Flutter callback receives authorization code
```

## Run

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=AUTH_CLIENT_ID=your-client-id \
  --dart-define=AUTH_SCOPE=openid+offline+paotangid.citizen
```

## Config

All bridge names are configurable with `--dart-define`.

| Key | Default |
|---|---|
| `AUTH_CLIENT_ID` | empty |
| `AUTH_SCOPE` | empty |
| `JS_BRIDGE_OBJECT` | `JSBridge` |
| `FLUTTER_CALLBACK_OBJECT` | `bridge` |
| `IOS_MESSAGE_HANDLER` | `observer` |
| `AUTH_METHOD_NAME` | `initAuth` |
| `AUTH_CALLBACK_NAME` | `initAuthCallback` |
| `AUTH_ERROR_CALLBACK_NAME` | `initAuthCallbackError` |
| `SHARE_METHOD_NAME` | `shareContent` |
| `SHARE_CALLBACK_NAME` | `shareContentCallback` |
| `SHARE_ERROR_CALLBACK_NAME` | `shareContentCallbackError` |

## Native Callback Contract

Success:

```js
window.bridge.initAuthCallback('AUTHORIZATION_CODE');
```

Error:

```js
window.bridge.initAuthCallbackError('ERROR_CODE', 'ERROR_DESCRIPTION');
```

## Android Contract

Flutter calls:

```js
// initAuth — positional string args
window.JSBridge.initAuth(clientId, scope);

// shareContent — single JSON-string arg
window.JSBridge.shareContent(jsonString);
// jsonString is JSON.stringify({ name, title?, description?, content, icon?, type })
```

## iOS Contract

Flutter posts:

```js
window.webkit.messageHandlers.observer.postMessage({
  name: 'initAuth',
  clientId: clientId,
  scope: scope
});

window.webkit.messageHandlers.observer.postMessage({
  name: 'shareContent',
  title: title,         // optional
  description: description, // optional
  content: content,
  icon: icon,           // optional, base64
  type: type            // 'TEXT' | 'IMAGE'
});
```

## shareContent Callbacks

```js
window.bridge.shareContentCallback('com.example.app'); // packageName may be null
window.bridge.shareContentCallbackError('MAW2025', 'Invalid Input');
// Error codes: MAW2026 (missing required), MAW2025 (invalid type), MAW2027 (invalid content)
```

## Browser Testing Mock

When running in Chrome, there is no native bridge by default. You can paste this in DevTools before clicking the button:

```js
window.JSBridge = {
  initAuth: function(clientId, scope) {
    console.log('mock initAuth', clientId, scope);
    setTimeout(() => {
      window.bridge.initAuthCallback('mock-auth-code-123');
    }, 500);
  }
};
```

Error mock:

```js
window.JSBridge = {
  initAuth: function(clientId, scope) {
    setTimeout(() => {
      window.bridge.initAuthCallbackError('AUTH_FAILED', 'Mock auth failed');
    }, 500);
  }
};
```

Share mock:

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.shareContent = function(jsonString) {
  console.log('mock shareContent', JSON.parse(jsonString));
  setTimeout(() => {
    window.bridge.shareContentCallback('com.mock.app');
  }, 500);
};
```

Share error mock:

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.shareContent = function(jsonString) {
  setTimeout(() => {
    window.bridge.shareContentCallbackError('MAW2025', 'Invalid Input');
  }, 500);
};
```

## Structure

```text
lib/
  app/
  bridge/
  config/
  features/
    auth/
    share/
```

- `config`: runtime configuration from `--dart-define`
- `bridge`: low-level JS interop only
- `features/auth`: app-level auth use case
- `features/share`: app-level share use case
- `app`: UI only

## Notes

- This project targets Flutter Web running inside a native WebView.
- Normal browsers do not have `window.JSBridge` or `window.webkit.messageHandlers` unless you mock them.
- App source does not hardcode client ID, scope, callback names, or handler names.
