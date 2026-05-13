import 'dart:js_interop';

@JS()
external JSObject get window;

extension JSObjectProperties on JSObject {
  external JSAny? getProperty(JSString name);
  external void setProperty(JSString name, JSAny? value);
}

extension JSObjectAccess on JSObject {
  JSObject? getJSObject(String name) {
    final value = getProperty(name.toJS);
    return (value != null && value.isA<JSObject>()) ? value as JSObject : null;
  }

  JSFunction? getJSFunction(String name) {
    final value = getProperty(name.toJS);
    return (value != null && value.isA<JSFunction>()) ? value as JSFunction : null;
  }

  void setJSObject(String name, JSObject value) => setProperty(name.toJS, value);

  void setJSFunction(String name, JSFunction value) => setProperty(name.toJS, value);
}

JSObject? lookupPath(JSObject root, List<String> path) {
  JSObject? current = root;
  for (final segment in path) {
    current = current?.getJSObject(segment);
    if (current == null) return null;
  }
  return current;
}

JSObject createJsObject(Map<String, Object?> value) {
  return value.jsify() as JSObject;
}
