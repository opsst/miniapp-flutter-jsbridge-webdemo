# 1. Flutter ใช้งาน JSBridge อย่างไร (Web ↔ Native App)

> เอกสารนี้แปลมาจาก [`01-jsbridge-architecture.md`](./01-jsbridge-architecture.md) — หากเนื้อหาขัดแย้งกัน ให้ยึดต้นฉบับภาษาอังกฤษเป็นหลัก

เอกสารนี้อธิบายวิธีที่ `flutter_jsbridge_sample` (Flutter Web) คุยกับ native host (Android `WebView` หรือ iOS `WKWebView`) ผ่าน JS bridge — และ native host คุยกลับมาอย่างไร

> กลุ่มเป้าหมาย: นักพัฒนาที่ต้องการต่อยอดหรืออินทิเกรต Flutter Web miniapp ตัวนี้

---

## 1.1 ภาพรวม

Flutter Web app จะถูกโหลดเข้าไปอยู่ใน **WebView ของเนทีฟ** ตัว WebView จะฉีด JS surface สำหรับแต่ละแพลตฟอร์มเข้ามาที่ `window` ดังนี้:

| แพลตฟอร์ม | Surface ที่ Flutter เรียกออกไป | รูปแบบ |
|---|---|---|
| Android | `window.JSBridge.<methodName>(...)` | JS object ที่มี property เป็นฟังก์ชันที่ฝั่ง Android เปิดให้ผ่าน `@JavascriptInterface` |
| iOS | `window.webkit.messageHandlers.<handler>.postMessage(payload)` | `WKScriptMessageHandler` ที่ลงทะเบียนไว้กับ user content controller ของ WKWebView |

ฝั่งเนทีฟจะคุยกลับมาหา Flutter ผ่าน **JS object เดียวที่ Flutter เป็นเจ้าของ** คือ:

```
window.bridge.<callbackName>(...args)
```

Flutter จะสร้าง `window.bridge` ขึ้นแบบ lazy และลงทะเบียนฟังก์ชัน callback ไว้บนนั้นก่อนแต่ละครั้งที่จะเรียก เนทีฟจะเรียกฟังก์ชันเหล่านั้นเมื่อทำงานเสร็จ

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

## 1.2 การแบ่ง layer (ทิศทางเดียว จากบนลงล่าง)

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

แผนผังของ source:

| โฟลเดอร์ | หน้าที่ | ไฟล์หลัก |
|---|---|---|
| `lib/config/` | แปลง `--dart-define` → config แบบ typed | `app_config.dart`, `bridge_config.dart`, `auth_config.dart` |
| `lib/bridge/` | JS interop และ boilerplate ของ callable | `js_interop_utils.dart`, `native_bridge.dart`, `bridge_result.dart` |
| `lib/features/<name>/` | Controller + state ต่อ bridge call หนึ่งตัว | `*_controller.dart`, `*_state.dart` |
| `lib/app/` | Material UI ล้วน ๆ | `app.dart`, `<name>_section.dart` |
| `lib/main.dart` | wire ทุกอย่างเข้าด้วยกันครั้งเดียว | — |

**กฎ:** UI ห้าม import `bridge/` controller ห้าม import `dart:js_interop*` มีแค่ `bridge/` เท่านั้นที่อ่าน/เขียน `window`

---

## 1.3 เลเยอร์ config (`lib/config/`)

ชื่อของ JS object / method / callback ทั้งหมดถูกตั้งค่าได้ผ่าน `--dart-define` เพื่อให้ Dart binary ตัวเดียวสามารถส่งไปใช้กับ native host หลายแบบได้

`BridgeConfig.fromEnvironment()` (`lib/config/bridge_config.dart:44`) อ่านค่า key พร้อม default ที่ปลอดภัย:

| `--dart-define` key | ค่า default | ใช้เป็น |
|---|---|---|
| `JS_BRIDGE_OBJECT` | `JSBridge` | `window.<...>` (entry object ฝั่ง Android) |
| `FLUTTER_CALLBACK_OBJECT` | `bridge` | `window.<...>` (ที่ที่ Flutter ติดตั้ง callback) |
| `IOS_MESSAGE_HANDLER` | `observer` | `window.webkit.messageHandlers.<...>` |
| `AUTH_METHOD_NAME` | `initAuth` | ชื่อ method ฝั่ง Android + ค่าฟิลด์ `name` ใน payload ของ iOS |
| `AUTH_CALLBACK_NAME` | `initAuthCallback` | callback สำเร็จที่ลงทะเบียนไว้บน `window.bridge` |
| `AUTH_ERROR_CALLBACK_NAME` | `initAuthCallbackError` | callback error ที่ลงทะเบียนไว้บน `window.bridge` |
| `SHARE_METHOD_NAME` | `shareContent` | … |
| `SHARE_CALLBACK_NAME` | `shareContentCallback` | … |
| `SHARE_ERROR_CALLBACK_NAME` | `shareContentCallbackError` | … |
| `SAVE_IMAGE_METHOD_NAME` | `saveImageToGallery` | … |
| `SAVE_IMAGE_CALLBACK_NAME` | `saveImageToGalleryCallback` | … |
| `SAVE_IMAGE_ERROR_CALLBACK_NAME` | `saveImageToGalleryCallbackError` | … |
| `OPEN_PAYMENT_METHOD_NAME` | `openPayment` | … |
| `OPEN_PAYMENT_ERROR_CALLBACK_NAME` | `openPaymentCallbackError` | error เท่านั้น — ไม่มี success callback |
| `AUTH_CLIENT_ID`, `AUTH_SCOPE` | (ค่า default ของตัวอย่าง) | พารามิเตอร์ auth ตอน runtime |

`AppConfig.fromEnvironment()` (`lib/config/app_config.dart:13`) ถูกสร้างครั้งเดียวใน `main.dart:12` แล้วถูก inject ลงไปข้างล่าง **ไม่มีไฟล์อื่นอ่าน `String.fromEnvironment` โดยตรง**

---

## 1.4 ตัวช่วย JS interop (`lib/bridge/js_interop_utils.dart`)

ไฟล์นี้เป็นไฟล์เดียวที่ได้รับอนุญาตให้เข้าถึง JS property แบบดิบ ๆ ใช้ `dart:js_interop` (รุ่นใหม่ แนะนำให้ใช้) ร่วมกับ `getProperty` / `setProperty` จาก `dart:js_interop_unsafe` สำหรับ lookup ชื่อแบบ dynamic

ไฟล์นี้เปิด API แบบ typed เล็ก ๆ ให้ที่อื่นใช้:

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

> ⚠️ **อย่า** ประกาศ `external getProperty` / `setProperty` ซ้ำในไฟล์นี้ — มันจะไม่ bind ตอน runtime ให้ import `dart:js_interop_unsafe` มาใช้แทนเสมอ

---

## 1.5 แกนกลางของ bridge (`lib/bridge/native_bridge.dart`)

`NativeBridge` เป็นคลาสเดียวที่แตะ `window` ภายในประกอบด้วย 4 method (หนึ่ง method ต่อหนึ่ง native capability) และ helper ที่แชร์กันอีกไม่กี่ตัว

### 1.5.1 รูปแบบการเรียก (ทุก method ทำตามแพตเทิร์นนี้)

```dart
Future<BridgeResult<void>> someMethod({...args, required onSuccess, required onError}) async {
  _registerSomeCallbacks(onSuccess: onSuccess, onError: onError); // 1. install callbacks on window.bridge
  if (/* args invalid */) return BridgeFailure(code: 'INVALID_CONFIG', ...); // 2. validate
  if (_invokeAndroidSome(...)) return BridgeSuccess(null);                    // 3. try Android
  if (_postIos({...}))           return BridgeSuccess(null);                  // 4. try iOS
  return _bridgeNotFound('someMethod');                                       // 5. neither host present
}
```

หลักสำคัญที่ต้องคงไว้:
- **ลงทะเบียน callback ก่อน** ก่อนจะเรียก native ด้วยซ้ำ เพื่อกันกรณีที่ handler ฝั่ง native ทำงานเร็วมากแล้ว callback ของเรายังไม่พร้อมรับ
- **Android ก่อน แล้วค่อย iOS** — ไม่มีการตรวจสอบ platform ตัว bridge จะลองเรียก Android ก่อน ถ้า `window.JSBridge.<method>` ไม่ใช่ฟังก์ชัน ก็จะไหลลงไปลอง iOS ต่อ
- **ทุก method คืนค่าเป็น `BridgeResult<void>`** — เป็น `BridgeSuccess(null)` หรือ `BridgeFailure(code, message)` (`lib/bridge/bridge_result.dart`) ผลลัพธ์แบบ async จะมาถึงผ่าน callback ที่ลงทะเบียนไว้ ส่วน `Future` ที่ return ออกมาเพียงบอกว่า "การกระโดดข้าม bridge สำเร็จ" เท่านั้น

### 1.5.2 การเรียกฝั่ง Android (แตกต่างกันแต่ละ method)

contract ของฝั่ง Android **ไม่เหมือนกันทุก method** แต่ละ method แพ็ค argument แตกต่างกันไป:

| Method | รูปแบบการเรียกของ Android |
|---|---|
| `initAuth` | `window.JSBridge.initAuth(clientId, scope)` — **positional string args** |
| `shareContent` | `window.JSBridge.shareContent(jsonString)` — **JSON string เดียว** ที่บรรจุ `{name, title?, description?, content, icon?, type}` |
| `saveImageToGallery` | `window.JSBridge.saveImageToGallery(base64Data)` — **string เดียว** |
| `openPayment` | `window.JSBridge.openPayment(txnRefId)` — **string เดียว** |

ใน Dart จะเขียนประมาณนี้ (ดู `_invokeAndroidShare` ที่ `lib/bridge/native_bridge.dart:132`):

```dart
final bridge = window.getJSObject(config.jsBridgeObjectName);
final method = bridge?.getJSFunction(config.shareMethodName);
if (bridge == null || method == null) return false;

method.callAsFunction(bridge, jsonEncode(payload).toJS);
return true;
```

### 1.5.3 การเรียกฝั่ง iOS (เหมือนกันทุก method)

iOS ใช้ helper ตัวเดียวร่วมกัน — `_postIos(Map)` (`lib/bridge/native_bridge.dart:239`):

```dart
final handler     = lookupPath(window, ['webkit', 'messageHandlers', config.iosMessageHandlerName]);
final postMessage = handler?.getJSFunction('postMessage');
if (handler == null || postMessage == null) return false;

postMessage.callAsFunction(handler, createJsObject(payload));
return true;
```

ทุก payload ของ iOS มีรูปแบบ `{name: '<methodName>', ...args}` ฝั่งเนทีฟจะ dispatch ตามค่าของ `payload.name`

### 1.5.4 การลงทะเบียน callback (แตกต่างกันแต่ละ method)

callback ทุกตัวจะถูกติดตั้งอยู่บน `window.<FLUTTER_CALLBACK_OBJECT>` (default คือ `window.bridge`) object นี้จะถูกสร้างแบบ lazy ในการเรียกครั้งแรกโดย `_ensureCallbackObject()` (`native_bridge.dart:248`)

แต่ละ method ลงทะเบียน callback เฉพาะตัวที่ต้องการ:

| Method | Callback ที่ลงทะเบียน (บน `window.bridge`) | รูปแบบ argument |
|---|---|---|
| `initAuth` | `initAuthCallback`, `initAuthCallbackError` | `(JSString code)` / `(JSString code, JSString description)` |
| `shareContent` | `shareContentCallback`, `shareContentCallbackError` | `(JSString? packageName)` / `(JSString code, JSString description)` |
| `saveImageToGallery` | `saveImageToGalleryCallback`, `saveImageToGalleryCallbackError` | `(JSBoolean success)` / `(JSString code, JSString description)` |
| `openPayment` | `openPaymentCallbackError` **เท่านั้น** | `(JSString code, JSString description)` — เมื่อสำเร็จ เนทีฟจะ reload WebView ด้วย deeplink URL |

การลงทะเบียนคือการเรียก `setJSFunction` พร้อม closure ที่ถูก `.toJS` มาแล้ว เช่น (`native_bridge.dart:53`):

```dart
callbacks.setJSFunction(
  config.authCallbackName,
  ((JSString code) => onSuccess(code.toDart)).toJS,
);
```

---

## 1.6 เลเยอร์ feature (`lib/features/<name>/`)

แต่ละ feature ประกอบด้วย:
- **คลาส state** (`enum <Name>Status { idle, loading, success, failure }` + value object หนึ่งตัว)
- **controller** (`extends ChangeNotifier`) ที่มี action method สาธารณะหนึ่งตัว

controller เป็นที่เดียวที่รู้ว่าจะแมปผลลัพธ์จาก bridge ไปเป็น state ของ UI อย่างไร โดยจะทำตามรูปแบบนี้เสมอ:
1. ดัน state เป็น `loading`
2. เรียก bridge พร้อม lambda `onSuccess` / `onError` ที่จะดัน state เป็น `success` / `failure`
3. หลัง `await` ถ้า bridge hop คืน `BridgeFailure` (เช่น หาเนทีฟไม่เจอ) ให้ดัน state เป็น `failure` พร้อม code/message ตัวนั้น

ตัวอย่าง — `AuthController` (`lib/features/auth/auth_controller.dart:15`):

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

จุดเด่นของ state แต่ละตัว:
- `AuthState` ถือค่า `authorizationCode`
- `ShareState` ถือค่า `packageName` (nullable)
- `SaveImageState` ถือค่า `bool success` — callback สำเร็จของฝั่งเนทีฟคืน `bool` มา ถ้าได้ `false` controller จะแมปให้กลายเป็น `failure`
- `PaymentState` **ไม่มีค่า `success`** — มีแค่ `idle | sending | failure` เพราะเมื่อสำเร็จเนทีฟจะนำทางออกไปเอง

---

## 1.7 เลเยอร์ UI (`lib/app/`)

`HomePage` (`lib/app/app.dart:49`) วางสี่ section ซ้อนกันใน `SingleChildScrollView` ได้แก่ `AuthSection`, `ShareSection`, `SaveImageSection`, `PaymentSection` แต่ละ section ทำหน้าที่:
- ถือ `TextEditingController` ของช่องกรอกต่าง ๆ
- ห่อด้วย `AnimatedBuilder(animation: controller, ...)` เพื่อรีบิลด์เมื่อ controller เรียก `notifyListeners()`
- แสดงปุ่มที่จะเรียก action method ของ controller
- แสดง `_StatusCard` ที่ switch ตาม enum ของ status

UI ตั้งใจให้ "โง่" — ไม่เรียก JS ไม่อ่าน env vars เลย

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

`BridgeConfig` หนึ่งตัว `NativeBridge` หนึ่งตัว และ controller สี่ตัว สิ่งที่เพิ่มเข้ามาใหม่ก็ควรอยู่ในรูปแบบเดียวกันนี้

---

## 1.9 ลำดับเหตุการณ์ปลายทางถึงปลายทางของการเรียกหนึ่งครั้ง (ตัวอย่าง initAuth)

1. ผู้ใช้พิมพ์ Client ID + Scope แล้วกด **Start Init Auth** ใน `AuthSection`
2. `AuthSection` เรียก `authController.initAuth(clientId, scope)`
3. `AuthController` ดัน state เป็น `loading` แล้ว await `nativeBridge.initAuth(...)`
4. `NativeBridge`:
   1. ตรวจให้แน่ใจว่ามี `window.bridge` อยู่ แล้วติดตั้ง `initAuthCallback` กับ `initAuthCallbackError` ลงไป
   2. ลองเรียก `window.JSBridge.initAuth(clientId, scope)` (Android) ถ้าเจอและเรียกได้ จะ return `BridgeSuccess`
   3. ถ้าไม่ ลองเรียก `window.webkit.messageHandlers.observer.postMessage({name:'initAuth', clientId, scope})` (iOS) แล้ว return `BridgeSuccess`
   4. ถ้ายังไม่ได้อีก จะ return `BridgeFailure('BRIDGE_NOT_FOUND', ...)`
5. เนทีฟทำการ authenticate แล้วเรียก **ตัวใดตัวหนึ่ง**:
   - `window.bridge.initAuthCallback('AUTHORIZATION_CODE')` → controller ดัน state เป็น `success`
   - `window.bridge.initAuthCallbackError('CODE', 'DESC')` → controller ดัน state เป็น `failure`
6. `_StatusCard` รีบิลด์ผ่าน `AnimatedBuilder`

---

## 1.10 การทดสอบบนเบราเซอร์โดยไม่มี native host จริง

Chrome ปกติไม่มี `window.JSBridge` หรือ `webkit.messageHandlers` หากต้องการทดสอบบน DevTools ให้วางสคริปต์ mock **ก่อน** กดปุ่ม:

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

mock ที่เทียบเท่าสำหรับ `shareContent`, `saveImageToGallery`, และ `openPayment` อยู่ใน `README.md` หัวข้อ **Browser Testing Mock**

---

## 1.11 ทำไมจึงออกแบบแบบนี้

- **แยก UI ออกจาก JS อย่างชัดเจน** UI รู้จักแค่ `Controller` controller รู้จักแค่ `NativeBridge` มีแค่ `NativeBridge` เท่านั้นที่แตะ `window` การเปลี่ยนชื่อ JS callback หรือสลับจาก `JSBridge` ไปเป็น `MyBridge` แก้ไฟล์เดียวที่ `bridge_config.dart` (หรือแค่ส่ง `--dart-define`) ก็จบ
- **ตั้งค่าได้ทุกอย่าง** native host ที่ต่างกัน (ต่างแบรนด์ / ต่าง build flavor) สามารถใช้ Dart binary ตัวเดียวกันได้โดย override ผ่าน `--dart-define`
- **JS interop แบบ typed** `js_interop_utils.dart` ตัด boilerplate แบบ null/`isA`/cast ที่ต้องเขียนซ้ำ ๆ ออกไป ทำให้ code เฉพาะ feature ใน `native_bridge.dart` อ่านง่ายขึ้น
- **ใช้ `BridgeResult<T>` แทนการ throw** ทำให้ controller จัดการกรณี "ไม่มีเนทีฟอยู่" ได้ในรูปแบบเดียวกับกรณี "callback คืน error" มา
