import 'session_record_store.dart';

SessionRecordStorage createDefaultSessionRecordStorage() {
  return InMemorySessionRecordStorage();
}
