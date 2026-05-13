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

## Deploy to GitHub Pages

This repository includes a workflow at `.github/workflows/deploy-pages.yml` that builds Flutter Web and deploys it to GitHub Pages.

1. Push to `main`.
2. In GitHub, go to **Settings -> Pages**.
3. Set **Source** to **GitHub Actions**.
4. Wait for the workflow **Deploy Flutter Web to GitHub Pages** to finish.

URL format:

- Project pages: `https://<owner>.github.io/<repo>/`
- User/org pages (`<owner>.github.io` repo): `https://<owner>.github.io/`

The workflow auto-selects the correct `--base-href` based on repository name.

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
| `SAVE_IMAGE_METHOD_NAME` | `saveImageToGallery` |
| `SAVE_IMAGE_CALLBACK_NAME` | `saveImageToGalleryCallback` |
| `SAVE_IMAGE_ERROR_CALLBACK_NAME` | `saveImageToGalleryCallbackError` |
| `OPEN_PAYMENT_METHOD_NAME` | `openPayment` |
| `OPEN_PAYMENT_ERROR_CALLBACK_NAME` | `openPaymentCallbackError` |

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

// saveImageToGallery — single base64 string arg
window.JSBridge.saveImageToGallery(base64Data);

// openPayment — single txnRefId string arg
window.JSBridge.openPayment(txnRefId);
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

window.webkit.messageHandlers.observer.postMessage({
  name: 'saveImageToGallery',
  base64Str: base64Data
});

window.webkit.messageHandlers.observer.postMessage({
  name: 'openPayment',
  txnRefId: txnRefId
});
```

## shareContent Callbacks

```js
window.bridge.shareContentCallback('com.example.app'); // packageName may be null
window.bridge.shareContentCallbackError('MAW2025', 'Invalid Input');
// Error codes: MAW2026 (missing required), MAW2025 (invalid type), MAW2027 (invalid content)
```

## saveImageToGallery Callbacks

```js
window.bridge.saveImageToGalleryCallback(true); // boolean: true on success, false on failure
window.bridge.saveImageToGalleryCallbackError('MAW1001', 'Access Denied');
// Error codes: MAW1001 (permission denied), MAW1002 (permission settings denied), MAW9999 (other)
```

## openPayment Callbacks

No success callback — on success native reloads the WebView with the deeplink URL.

```js
window.bridge.openPaymentCallbackError('MAW2002', 'Required reference ID is missing or invalid');
// Fixed error codes:
//   MAW1001 (permission denied)
//   MAW2002 (txnRefId missing/invalid)
//   MAW2005 (user cancelled at source-of-fund screen)
//   MAW9999 (unexpected)
// Plus dynamic statusCd/statusDesc from the sandbox API or Pay-with-Paotang service.
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

Save-image mock:

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.saveImageToGallery = function(base64Data) {
  console.log('mock saveImageToGallery, length=', base64Data.length);
  setTimeout(() => {
    window.bridge.saveImageToGalleryCallback(true);
  }, 500);
};
```

Save-image error mock (permission denied):

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.saveImageToGallery = function(base64Data) {
  setTimeout(() => {
    window.bridge.saveImageToGalleryCallbackError('MAW1001', 'Access Denied');
  }, 500);
};
```

Open-payment mock (no success callback — only error fires):

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.openPayment = function(txnRefId) {
  console.log('mock openPayment txnRefId=', txnRefId);
  // Real native would either reload the WebView (success) or call:
  setTimeout(() => {
    window.bridge.openPaymentCallbackError('MAW2005', 'User Canceled payment flow');
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
    save_image/
    payment/
```

- `config`: runtime configuration from `--dart-define`
- `bridge`: low-level JS interop only
- `features/auth`: app-level auth use case
- `features/share`: app-level share use case
- `features/save_image`: app-level save-to-gallery use case
- `features/payment`: app-level Pay-with-Paotang use case
- `app`: UI only

## Notes

- This project targets Flutter Web running inside a native WebView.
- Normal browsers do not have `window.JSBridge` or `window.webkit.messageHandlers` unless you mock them.
- App source does not hardcode client ID, scope, callback names, or handler names.
