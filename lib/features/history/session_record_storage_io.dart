import 'dart:io';

import 'session_record_store.dart';

SessionRecordStorage createDefaultSessionRecordStorage() {
  return FileSessionRecordStorage(File('.calmturn_session_records.json'));
}

final class FileSessionRecordStorage implements SessionRecordStorage {
  final File file;

  const FileSessionRecordStorage(this.file);

  @override
  Future<String?> read() async {
    if (!await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  @override
  Future<void> write(String value) async {
    await file.writeAsString(value, flush: true);
  }

  @override
  Future<void> clear() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
