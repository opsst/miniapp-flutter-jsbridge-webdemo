# Flutter Web JSBridge Sample

A small Flutter Web sample for calling a native JSBridge from Flutter Web running inside a native WebView.

## Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Configuration](#configuration)
- [Bridge Features](#bridge-features)
  - [initAuth](#initauth)
  - [shareContent](#sharecontent)
  - [saveImageToGallery](#saveimagetogallery)
  - [openPayment](#openpayment)
- [Browser Testing](#browser-testing)
- [Deploy to GitHub Pages](#deploy-to-github-pages)
- [Notes](#notes)

## Quick Start

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=AUTH_CLIENT_ID=your-client-id \
  --dart-define=AUTH_SCOPE=openid+offline+paotangid.citizen
```

## Architecture

```text
Flutter Web
  -> NativeBridge.<method>(args)
  -> Android: window.JSBridge.<method>(args)
  -> iOS:     window.webkit.messageHandlers.<handler>.postMessage(payload)
  -> Native callback: window.bridge.<callback>(...)
  -> Flutter callback receives result
```

Source layout:

```text
lib/
  app/                 # UI only
  bridge/              # low-level JS interop only
  config/              # runtime configuration from --dart-define
  features/
    auth/              # initAuth use case
    share/             # shareContent use case
    save_image/        # saveImageToGallery use case
    payment/           # openPayment use case (Pay-with-Paotang)
```

## Configuration

All bridge names are configurable with `--dart-define`. App source does not hardcode client ID, scope, callback names, or handler names.

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

## Bridge Features

Each feature has the same shape: an Android call, an iOS `postMessage` payload, and one or more callbacks invoked on `window.bridge`.

### initAuth

**Android call** — positional string args:

```js
window.JSBridge.initAuth(clientId, scope);
```

**iOS payload:**

```js
window.webkit.messageHandlers.observer.postMessage({
  name: 'initAuth',
  clientId: clientId,
  scope: scope
});
```

**Callbacks:**

```js
// success
window.bridge.initAuthCallback('AUTHORIZATION_CODE');
// error
window.bridge.initAuthCallbackError('ERROR_CODE', 'ERROR_DESCRIPTION');
```

**Mock — success:**

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

**Mock — error:**

```js
window.JSBridge = {
  initAuth: function(clientId, scope) {
    setTimeout(() => {
      window.bridge.initAuthCallbackError('AUTH_FAILED', 'Mock auth failed');
    }, 500);
  }
};
```

### shareContent

**Android call** — single JSON-string arg:

```js
window.JSBridge.shareContent(jsonString);
// jsonString = JSON.stringify({ name, title?, description?, content, icon?, type })
```

**iOS payload:**

```js
window.webkit.messageHandlers.observer.postMessage({
  name: 'shareContent',
  title: title,             // optional
  description: description, // optional
  content: content,
  icon: icon,               // optional, base64
  type: type                // 'TEXT' | 'IMAGE'
});
```

**Callbacks:**

```js
// success — packageName may be null
window.bridge.shareContentCallback('com.example.app');
// error
window.bridge.shareContentCallbackError('MAW2025', 'Invalid Input');
// Error codes: MAW2026 (missing required), MAW2025 (invalid type), MAW2027 (invalid content)
```

**Mock — success:**

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.shareContent = function(jsonString) {
  console.log('mock shareContent', JSON.parse(jsonString));
  setTimeout(() => {
    window.bridge.shareContentCallback('com.mock.app');
  }, 500);
};
```

**Mock — error:**

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.shareContent = function(jsonString) {
  setTimeout(() => {
    window.bridge.shareContentCallbackError('MAW2025', 'Invalid Input');
  }, 500);
};
```

### saveImageToGallery

**Android call** — single base64 string arg:

```js
window.JSBridge.saveImageToGallery(base64Data);
```

**iOS payload:**

```js
window.webkit.messageHandlers.observer.postMessage({
  name: 'saveImageToGallery',
  base64Str: base64Data
});
```

**Callbacks:**

```js
// success callback receives a boolean — false also maps to failure in Flutter state
window.bridge.saveImageToGalleryCallback(true);
// error
window.bridge.saveImageToGalleryCallbackError('MAW1001', 'Access Denied');
// Error codes: MAW1001 (permission denied), MAW1002 (permission settings denied), MAW9999 (other)
```

**Mock — success:**

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.saveImageToGallery = function(base64Data) {
  console.log('mock saveImageToGallery, length=', base64Data.length);
  setTimeout(() => {
    window.bridge.saveImageToGalleryCallback(true);
  }, 500);
};
```

**Mock — error (permission denied):**

```js
window.JSBridge = window.JSBridge || {};
window.JSBridge.saveImageToGallery = function(base64Data) {
  setTimeout(() => {
    window.bridge.saveImageToGalleryCallbackError('MAW1001', 'Access Denied');
  }, 500);
};
```

### openPayment

**Android call** — single txnRefId string arg:

```js
window.JSBridge.openPayment(txnRefId);
```

**iOS payload:**

```js
window.webkit.messageHandlers.observer.postMessage({
  name: 'openPayment',
  txnRefId: txnRefId
});
```

**Callbacks:**

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

**Mock (error-only, since success is a navigation):**

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

## Browser Testing

Normal browsers do not expose `window.JSBridge` or `window.webkit.messageHandlers`. To exercise a feature in Chrome, paste the matching mock from the [Bridge Features](#bridge-features) section into DevTools before invoking the action from the UI.

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

## Notes

- This project targets Flutter Web running inside a native WebView.
- Normal browsers do not have `window.JSBridge` or `window.webkit.messageHandlers` unless you mock them.
- App source does not hardcode client ID, scope, callback names, or handler names.
