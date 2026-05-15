import 'package:calmturn/features/history/session_record.dart';
import 'package:calmturn/features/timer/domain/timer_engine.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

void main() {
  final tests = <String, void Function()>{
    'session record copies timer results without recalculating totals': () {
      final config = _config();
      final engine = TimerEngine.start(config);

      engine.tick(const Duration(seconds: 65));
      final snapshot = engine.snapshot();
      final record = SessionRecord.fromTimerSnapshot(
        id: 'record-1',
        config: config,
        snapshot: snapshot,
        startedAt: DateTime.utc(2026, 5, 15, 9),
        endedAt: DateTime.utc(2026, 5, 15, 9, 8),
        endReason: SessionEndReason.endedByUser,
        breakCount: 2,
        agreedNotes: 'Use shorter examples.',
        nextTopics: 'Budget follow-up.',
      );

      _expect(record.title == 'A / B', 'record title should use names');
      _expect(
        record.endReason == SessionEndReason.endedByUser,
        'end reason should be endedByUser',
      );
      _expect(record.config.turnLimitSeconds == 60, 'turn limit mismatch');
      _expect(
        record.config.overtimeThresholdSeconds == 5,
        'overtime threshold mismatch',
      );
      _expect(record.breakCount == 2, 'break count mismatch');
      _expect(
        record.agreedNotes == 'Use shorter examples.',
        'agreed notes mismatch',
      );
      _expect(record.nextTopics == 'Budget follow-up.', 'next topics mismatch');

      final participantA = record.participantResults.first;
      _expect(participantA.name == 'A', 'participant A name mismatch');
      _expect(
        participantA.totalAllocatedSeconds == 300,
        'participant A allocation mismatch',
      );
      _expect(
        participantA.totalUsedSeconds == 65,
        'participant A used mismatch',
      );
      _expect(
        participantA.totalRemainingSeconds == 235,
        'participant A remaining mismatch',
      );
      _expect(
        participantA.overtimeTotalSeconds == 5,
        'participant A overtime mismatch',
      );
      _expect(participantA.penaltyCount == 1, 'participant A marks mismatch');

      final participantB = record.participantResults.last;
      _expect(participantB.name == 'B', 'participant B name mismatch');
      _expect(
        participantB.totalUsedSeconds == 0,
        'participant B used mismatch',
      );
      _expect(
        participantB.totalRemainingSeconds == 300,
        'participant B remaining mismatch',
      );
      _expect(
        participantB.overtimeTotalSeconds == 0,
        'participant B overtime mismatch',
      );
      _expect(participantB.penaltyCount == 0, 'participant B marks mismatch');
    },

    'session record round trips through json': () {
      final config = _config();
      final record = SessionRecord.fromTimerSnapshot(
        id: 'record-2',
        config: config,
        snapshot: TimerEngine.start(config).snapshot(),
        startedAt: DateTime.utc(2026, 5, 15, 10),
        endedAt: DateTime.utc(2026, 5, 15, 10, 5),
        endReason: SessionEndReason.timeEnded,
        breakCount: 1,
        agreedNotes: 'Keep the first topic.',
        nextTopics: 'Decide next weekend.',
      );

      final decoded = SessionRecord.fromJson(record.toJson());

      _expect(decoded.id == record.id, 'id should round trip');
      _expect(
        decoded.startedAt == record.startedAt,
        'startedAt should round trip',
      );
      _expect(decoded.endedAt == record.endedAt, 'endedAt should round trip');
      _expect(
        decoded.endReason == record.endReason,
        'reason should round trip',
      );
      _expect(
        decoded.config.alertChannels == record.config.alertChannels,
        'alert channels should round trip',
      );
      _expect(
        decoded.participantResults.singleWhere((item) => item.id == 'a').name ==
            'A',
        'participant result should round trip',
      );
      _expect(
        decoded.breakCount == record.breakCount,
        'break count should round trip',
      );
      _expect(
        decoded.agreedNotes == record.agreedNotes,
        'notes should round trip',
      );
      _expect(
        decoded.nextTopics == record.nextTopics,
        'topics should round trip',
      );
    },
  };

  for (final entry in tests.entries) {
    try {
      entry.value();
      print('PASS ${entry.key}');
    } catch (error, stackTrace) {
      print('FAIL ${entry.key}');
      print(error);
      print(stackTrace);
      throw StateError('session_record_test failed');
    }
  }
}

SessionConfig _config() {
  return SessionConfig(
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
    penaltyConfig: const PenaltyConfig(thresholdSeconds: 5),
    alertConfig: const AlertConfig(
      visualEnabled: true,
      soundEnabled: false,
      hapticEnabled: true,
    ),
  );
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}
