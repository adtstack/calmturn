import 'package:calmturn/features/history/session_record.dart';
import 'package:calmturn/features/history/session_record_store.dart';
import 'package:calmturn/features/timer/domain/timer_engine.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

Future<void> main() async {
  final tests = <String, Future<void> Function()>{
    'json store saves newest records first and deletes by id': () async {
      final store = JsonSessionRecordStore(
        storage: InMemorySessionRecordStorage(),
      );
      final older = _record('older', DateTime.utc(2026, 5, 15, 8));
      final newer = _record('newer', DateTime.utc(2026, 5, 15, 9));

      await store.save(older);
      await store.save(newer);

      var records = await store.load();
      _expectList(
        records.map((record) => record.id).toList(),
        ['newer', 'older'],
        'records should be newest first',
      );

      await store.delete('newer');
      records = await store.load();
      _expect(records.length == 1, 'one record should remain after delete');
      _expect(records.single.id == 'older', 'older record should remain');

      await store.clear();
      _expect((await store.load()).isEmpty, 'records should clear');
    },

    'json store replaces an existing record with the same id': () async {
      final store = JsonSessionRecordStore(
        storage: InMemorySessionRecordStorage(),
      );

      await store.save(_record('record-1', DateTime.utc(2026, 5, 15, 8)));
      await store.save(
        _record(
          'record-1',
          DateTime.utc(2026, 5, 15, 8),
          agreedNotes: 'Updated agreement.',
        ),
      );

      final records = await store.load();
      _expect(records.length == 1, 'record should be replaced');
      _expect(
        records.single.agreedNotes == 'Updated agreement.',
        'record notes should be updated',
      );
    },
  };

  for (final entry in tests.entries) {
    try {
      await entry.value();
      print('PASS ${entry.key}');
    } catch (error, stackTrace) {
      print('FAIL ${entry.key}');
      print(error);
      print(stackTrace);
      throw StateError('session_record_store_test failed');
    }
  }
}

SessionRecord _record(
  String id,
  DateTime startedAt, {
  String agreedNotes = 'Agreement.',
}) {
  final config = SessionConfig(
    participantA: const ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: 300,
    ),
    participantB: const ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: 300,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: const OvertimeConfig(),
    penaltyConfig: const PenaltyConfig(),
    alertConfig: const AlertConfig(),
  );

  return SessionRecord.fromTimerSnapshot(
    id: id,
    config: config,
    snapshot: TimerEngine.start(config).snapshot(),
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(minutes: 5)),
    endReason: SessionEndReason.endedByUser,
    breakCount: 0,
    agreedNotes: agreedNotes,
    nextTopics: null,
  );
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

void _expectList(List<String> actual, List<String> expected, String message) {
  if (actual.length != expected.length) {
    throw StateError('$message: length ${actual.length} != ${expected.length}');
  }
  for (var index = 0; index < actual.length; index += 1) {
    if (actual[index] != expected[index]) {
      throw StateError('$message: ${actual[index]} != ${expected[index]}');
    }
  }
}
