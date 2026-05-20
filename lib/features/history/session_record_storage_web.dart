import 'dart:js_interop';

import 'session_record_store.dart';

const _storageKey = 'calmturn.sessionRecords.v1';

@JS('window.localStorage')
external _WebStorage get _localStorage;

extension type _WebStorage(JSObject _) implements JSObject {
  external String? getItem(String key);

  external void setItem(String key, String value);

  external void removeItem(String key);
}

SessionRecordStorage createDefaultSessionRecordStorage() {
  return const WebSessionRecordStorage();
}

final class WebSessionRecordStorage implements SessionRecordStorage {
  const WebSessionRecordStorage();

  @override
  Future<String?> read() async {
    return _localStorage.getItem(_storageKey);
  }

  @override
  Future<void> write(String value) async {
    _localStorage.setItem(_storageKey, value);
  }

  @override
  Future<void> clear() async {
    _localStorage.removeItem(_storageKey);
  }
}
