import 'dart:convert';

import 'session_record.dart';
import 'session_record_storage_stub.dart'
    if (dart.library.io) 'session_record_storage_io.dart'
    if (dart.library.js_interop) 'session_record_storage_web.dart'
    as platform;

abstract interface class SessionRecordStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> clear();
}

abstract interface class SessionRecordStore {
  Future<List<SessionRecord>> load();

  Future<void> save(SessionRecord record);

  Future<void> delete(String id);

  Future<void> clear();
}

final class JsonSessionRecordStore implements SessionRecordStore {
  final SessionRecordStorage storage;

  const JsonSessionRecordStore({required this.storage});

  factory JsonSessionRecordStore.local() {
    return JsonSessionRecordStore(
      storage: platform.createDefaultSessionRecordStorage(),
    );
  }

  @override
  Future<List<SessionRecord>> load() async {
    final contents = await storage.read();
    if (contents == null || contents.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(contents) as Map<String, Object?>;
    final records = (decoded['records'] as List<Object?>)
        .map((item) => SessionRecord.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
    return _sortNewestFirst(records);
  }

  @override
  Future<void> save(SessionRecord record) async {
    final records = await load();
    final updated = [record, ...records.where((item) => item.id != record.id)];
    await _writeRecords(updated);
  }

  @override
  Future<void> delete(String id) async {
    final records = await load();
    await _writeRecords(records.where((record) => record.id != id).toList());
  }

  @override
  Future<void> clear() async {
    await storage.clear();
  }

  Future<void> _writeRecords(List<SessionRecord> records) async {
    final encoded = const JsonEncoder.withIndent('  ').convert({
      'records': _sortNewestFirst(
        records,
      ).map((record) => record.toJson()).toList(growable: false),
    });
    await storage.write(encoded);
  }

  List<SessionRecord> _sortNewestFirst(List<SessionRecord> records) {
    return List<SessionRecord>.of(records)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }
}

final class InMemorySessionRecordStorage implements SessionRecordStorage {
  String? _value;

  @override
  Future<String?> read() async {
    return _value;
  }

  @override
  Future<void> write(String value) async {
    _value = value;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}
