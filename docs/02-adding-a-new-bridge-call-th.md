# 2. วิธีเพิ่ม JSBridge Call ใหม่

> เอกสารนี้แปลมาจาก [`02-adding-a-new-bridge-call.md`](./02-adding-a-new-bridge-call.md) — หากเนื้อหาขัดแย้งกัน ให้ยึดต้นฉบับภาษาอังกฤษเป็นหลัก

นี่คือสูตรสำเร็จสำหรับการเพิ่ม native capability ใหม่ — สมมติว่าเป็น `getDeviceInfo` — เข้าไปใน Flutter Web miniapp ตัวนี้ ทำตามลำดับขั้นนี้ เพราะการแบ่ง layer ค่อนข้างเข้มงวด

> ถ้ายังไม่ได้อ่าน ให้อ่าน [`01-jsbridge-architecture-th.md`](./01-jsbridge-architecture-th.md) ก่อน

---

## 2.1 ก่อนเริ่ม: ตกลง contract กับฝั่งเนทีฟให้เรียบร้อย

มีสามอย่างที่คุณต้องได้จากทีมเนทีฟ:

1. **รูปแบบการเรียกของ Android** เลือกหนึ่งใน:
   - **Positional string args** — `window.JSBridge.foo(arg1, arg2, ...)` (แบบที่ `initAuth` ใช้)
   - **Single JSON-string arg** — `window.JSBridge.foo(JSON.stringify({...}))` (แบบที่ `shareContent` ใช้) เลือกแบบนี้เมื่อ payload มีโครงสร้างซับซ้อนหรือมีฟิลด์ optional
   - **Single string arg** — `window.JSBridge.foo(value)` (แบบที่ `saveImageToGallery` กับ `openPayment` ใช้) เลือกแบบนี้เมื่อมีค่าเดียว
2. **รูปแบบ payload ของ iOS** ฝั่ง iOS เป็นมาตรฐานเดียวกันหมด — ใช้ `webkit.messageHandlers.<handler>.postMessage({name:'<methodName>', ...args})` เสมอ คุณแค่ต้องตัดสินใจชื่อฟิลด์เท่านั้น
3. **รูปแบบของ callback** สำหรับแต่ละตัว ตัดสินใจ:
   - ชื่อ success callback + ชนิดของ argument (หรือ **ไม่มี success callback** ถ้าเนทีฟนำทางออกไปเองเมื่อสำเร็จ — ดู `openPayment`)
   - ชื่อ error callback + ชนิดของ argument (เกือบทุกครั้งจะเป็น `(code, description)`)

จดทุกอย่างเหล่านี้ไว้ใน README ใต้หัวข้อ **Android Contract**, **iOS Contract**, และในส่วน **Callbacks** ของ method นั้น ๆ

---

## 2.2 Checklist ทีละขั้น

ตัวอย่างด้านล่างเป็นการเพิ่ม call ที่สมมติขึ้นชื่อ `getDeviceInfo`:
- คืน `{deviceId, osVersion}` กลับมาผ่าน success callback
- Android: `window.JSBridge.getDeviceInfo(jsonString)` (single JSON-string arg)
- iOS: `webkit.messageHandlers.observer.postMessage({name: 'getDeviceInfo', requestId})`
- Success callback: `window.bridge.getDeviceInfoCallback(deviceId, osVersion)`
- Error callback: `window.bridge.getDeviceInfoCallbackError(code, description)`

### Step 1 — เพิ่ม config keys (`lib/config/bridge_config.dart`)

เพิ่มฟิลด์สามตัว (ชื่อ method + ชื่อ callback อีกสองตัว) แล้วอ่านค่าจาก env พร้อม default ที่ปลอดภัย:

```dart
final String getDeviceInfoMethodName;
final String getDeviceInfoCallbackName;
final String getDeviceInfoErrorCallbackName;
```

ในส่วน constructor และ `fromEnvironment()`:

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

> **อย่า** เพิ่ม env key สำหรับเช็คว่า "method นี้มีหรือเปล่า" — ตัว bridge ตรวจสอบการมีอยู่ของ host ตอน runtime ให้อยู่แล้ว

### Step 2 — เพิ่ม method ใน `NativeBridge` (`lib/bridge/native_bridge.dart`)

เพิ่ม typedef ไว้บนสุด:

```dart
typedef DeviceInfoSuccessCallback = void Function(String deviceId, String osVersion);
typedef DeviceInfoErrorCallback   = void Function(String errorCode, String errorDescription);
```

เพิ่ม method สาธารณะตาม **call pattern** ใน §1.5.1:

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

ลงทะเบียน callback:

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

เพิ่มตัวเรียกฝั่ง Android (เลียนแบบ `_invokeAndroidShare`):

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

> **สำคัญ:** เลือกตัวแปร Android ให้ตรงกับ contract ที่ตกลงกันใน §2.1
> - Positional args → เลียนแบบ `_invokeAndroidAuth` (ส่งแต่ละ arg แบบ `.toJS`)
> - JSON string → เลียนแบบ `_invokeAndroidShare` (ส่ง `jsonEncode(payload).toJS`)
> - Single string → เลียนแบบ `_invokeAndroidSaveImage` / `_invokeAndroidOpenPayment` (ส่ง string ตัวเดียวแบบ `.toJS`)
>
> **อย่า** คิดค้นรูปแบบที่สี่ขึ้นมาใหม่ ถ้าเนทีฟขอแบบอื่นให้คุยกลับ หรือใช้ JSON-string แทน

ฝั่ง iOS ใช้ `_postIos(payload)` ที่แชร์อยู่แล้ว — ไม่ต้องเขียน helper ใหม่ ยกเว้นกรณีที่มีรูปแบบเฉพาะกิจ

### Step 3 — กำหนด state (`lib/features/device_info/device_info_state.dart`)

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

> ถ้า method ของคุณ **ไม่มี success callback** (เนทีฟนำทางออกไปเอง) ให้ตัด `success` ออกจาก enum — ดู `PaymentState`
> ถ้า success คืน `bool` ให้แมป `false` เป็น `failure` แบบเดียวกับที่ `SaveImageController` ทำ

### Step 4 — กำหนด controller (`lib/features/device_info/device_info_controller.dart`)

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

โครงสร้าง — `loading → เรียก bridge → onSuccess/onError lambdas → จัดการ BridgeFailure หลัง await` — เหมือนกับทุก controller ตัวอื่น ๆ ห้ามเปลี่ยน

### Step 5 — เพิ่ม UI section (`lib/app/device_info_section.dart`)

ทำตามโครงสร้างของ `auth_section.dart`:
- `StatefulWidget` ที่ถือ `TextEditingController` สำหรับ input
- ห่อ body ด้วย `AnimatedBuilder(animation: widget.controller, builder: ...)`
- แสดง `FilledButton` ที่ `onPressed` จะเรียก action ของ controller
- แสดง `_StatusCard` พร้อม `switch` ตาม status enum ของ state

จากนั้นวางลงใน `HomePage` (`lib/app/app.dart:74`) ระหว่าง `Divider` สองตัว ให้เหมือน section อื่น ๆ:

```dart
const SizedBox(height: 32),
const Divider(),
const SizedBox(height: 32),
DeviceInfoSection(controller: deviceInfoController),
```

### Step 6 — wire เข้าใน `main.dart`

```dart
final deviceInfoController = DeviceInfoController(nativeBridge: bridge);

runApp(App(
  // ...existing controllers...
  deviceInfoController: deviceInfoController,
));
```

เพิ่มฟิลด์/พารามิเตอร์ลงใน constructor ของ `App` กับ `HomePage` (`lib/app/app.dart`) แล้วส่งต่อลงไปข้างล่าง

### Step 7 — อัปเดตตาราง contract ใน README

เพิ่มแถวเข้าไปที่:
- ตาราง **Config** — `--dart-define` keys ใหม่สามตัวของคุณ
- code block **Android Contract** — รูปแบบการเรียกฝั่ง JS
- code block **iOS Contract** — รูปแบบ payload ของ postMessage
- หัวข้อใหม่ที่ระบุ signature ของ callback + รหัส error
- snippet **Browser Testing Mock** ตัวใหม่ เพื่อให้ dev ทดสอบโดยไม่ต้องมีเนทีฟ (ดู template ด้านล่าง)

### Step 8 — เพิ่ม browser mock

snippet พร้อมวางใน DevTools (มีทั้งแบบสำเร็จและ error) ตามสไตล์เดียวกับ mock ที่มีอยู่ใน README:

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

### Step 9 — ตรวจสอบ

```bash
flutter pub get
flutter analyze                        # must be clean
flutter test                           # existing tests should still pass
flutter run -d chrome                  # then paste the mock, click your button, watch the status card
```

แล้วทดสอบบน native host จริง (Android emulator + iOS simulator) ก่อน merge

---

## 2.3 Cheat sheet — แก้ไฟล์ไหนเมื่อทำอะไร

| สิ่งที่กำลังเพิ่ม | ไฟล์ที่ต้องแตะ |
|---|---|
| bridge method ตัวใหม่ | `lib/config/bridge_config.dart` (3 keys), `lib/bridge/native_bridge.dart` (typedefs + method + Android invoker + callback registrar) |
| feature ตัวใหม่ | `lib/features/<name>/<name>_state.dart`, `lib/features/<name>/<name>_controller.dart` |
| section ใหม่บนหน้าจอ | `lib/app/<name>_section.dart`, แล้วเพิ่มลงใน `HomePage` ใน `lib/app/app.dart` |
| การ wire | `lib/main.dart`, รวมถึง parameter ใน constructor ของ `App` / `HomePage` ใน `lib/app/app.dart` |
| เอกสาร | `README.md` (Config table, Android Contract, iOS Contract, Callbacks, Browser Testing Mock) |

---

## 2.4 ข้อผิดพลาดที่พบบ่อย

- **เรียก JS จาก controller หรือ UI** อย่าทำ มีแค่ `lib/bridge/native_bridge.dart` เท่านั้นที่แตะ `window` ได้
- **hardcode ชื่อ bridge / method / callback** ที่อื่นนอกเหนือจาก `BridgeConfig` ให้อ่านจาก `config` เสมอ
- **อ่าน `String.fromEnvironment` นอก `lib/config/`** ค่า env ควรอ่านครั้งเดียวตอนสร้าง config
- **ประกาศ `external getProperty`/`setProperty` ซ้ำ** ใน `js_interop_utils.dart` มันจะไม่ bind ตอน runtime — ให้ import `dart:js_interop_unsafe` แทน
- **ลงทะเบียน callback หลังจากเรียก native** ลงทะเบียนก่อน เพราะ handler ฝั่งเนทีฟอาจทำงานแบบ synchronous
- **คิดค้น arg shape ใหม่ของ Android ขึ้นมาเอง** ให้ยึดหนึ่งในสามแพตเทิร์นที่มีอยู่ (positional / JSON-string / single-string)
- **ลืมจัดการสาขา `BridgeFailure` หลัง await ใน controller** ถ้าลืม กรณี "ไม่มี native host" จะเงียบหายไปโดยไม่มีอะไรขึ้น
- **เพิ่ม success state ให้กับ method ที่นำทางออกตอนสำเร็จ** ทำตามแพตเทิร์นใน `PaymentState` (ไม่มีค่า `success`)
- **เปลี่ยนรูปแบบ dispatch ของ iOS** ทุก payload ของ iOS ต้องมี `name: '<methodName>'` เพื่อให้เนทีฟ route ได้ ใช้ `_postIos` ซ้ำ

---

## 2.5 ตัวอย่างที่ใช้อ้างอิงได้

เวลาไม่แน่ใจ ให้ลอกจาก analog ที่ใกล้เคียงที่สุดที่มีอยู่:

| รูปแบบ Android ของ method คุณ | ใช้ตัวนี้เป็น template |
|---|---|
| Positional args | `_invokeAndroidAuth` (`lib/bridge/native_bridge.dart:63`) และ `initAuth` (`:26`) |
| Single JSON-string arg | `_invokeAndroidShare` (`:132`) และ `shareContent` (`:82`) |
| Single string arg | `_invokeAndroidSaveImage` (`:182`) / `_invokeAndroidOpenPayment` (`:227`) |
| success callback คืน `bool` | `SaveImageController.save` (`lib/features/save_image/save_image_controller.dart:15`) |
| ไม่มี success callback (เนทีฟนำทางออกเอง) | `openPayment` (`lib/bridge/native_bridge.dart:196`) และ `PaymentState` |
