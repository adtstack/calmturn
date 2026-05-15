import 'package:calmturn/features/timer/domain/timer_engine.dart';
import 'package:calmturn/features/timer/domain/timer_models.dart';

void main() {
  final tests = <String, void Function()>{
    'supports different total time per participant': () {
      final engine = TimerEngine.start(_config(aTotal: 300, bTotal: 600));

      final snapshot = engine.snapshot();

      _expectParticipant(
        snapshot,
        'a',
        totalAllocatedSeconds: 300,
        totalRemainingSeconds: 300,
      );
      _expectParticipant(
        snapshot,
        'b',
        totalAllocatedSeconds: 600,
        totalRemainingSeconds: 600,
      );
    },
    'normal tick decreases active total time and turn time': () {
      final engine = TimerEngine.start(_config(aTotal: 300, bTotal: 600));

      engine.tick(const Duration(seconds: 10));
      final snapshot = engine.snapshot();

      _expectParticipant(
        snapshot,
        'a',
        totalRemainingSeconds: 290,
        totalUsedSeconds: 10,
      );
      _expectParticipant(
        snapshot,
        'b',
        totalRemainingSeconds: 600,
        totalUsedSeconds: 0,
      );
      _expectEquals(snapshot.currentTurnRemainingSeconds, 50);
    },
    'turn warning fires once at warning threshold': () {
      final engine = TimerEngine.start(_config());

      final firstEvents = engine.tick(const Duration(seconds: 50));
      final secondEvents = engine.tick(const Duration(seconds: 1));

      _expectEquals(_eventsOf<TurnWarningEvent>(firstEvents).length, 1);
      _expectEquals(_eventsOf<TurnWarningEvent>(secondEvents).length, 0);
    },
    'total warning fires once at warning threshold': () {
      final engine = TimerEngine.start(_config(aTotal: 20));

      final firstEvents = engine.tick(const Duration(seconds: 10));
      final secondEvents = engine.tick(const Duration(seconds: 1));

      _expectEquals(_eventsOf<TotalWarningEvent>(firstEvents).length, 1);
      _expectEquals(_eventsOf<TotalWarningEvent>(secondEvents).length, 0);
    },
    'turn limit entering zero starts overtime': () {
      final engine = TimerEngine.start(_config());

      final events = engine.tick(const Duration(seconds: 60));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.runningOvertime);
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
      _expectEquals(_eventsOf<OvertimeStartedEvent>(events).length, 1);
    },
    'overtime increases overtime and active total usage': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 60));

      engine.tick(const Duration(seconds: 5));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.currentTurnOvertimeSeconds, 5);
      _expectParticipant(
        snapshot,
        'a',
        totalRemainingSeconds: 235,
        totalUsedSeconds: 65,
        overtimeTotalSeconds: 5,
      );
    },
    'overtime threshold records one penalty': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 60));

      final events = engine.tick(const Duration(seconds: 60));
      final snapshot = engine.snapshot();

      _expectParticipant(snapshot, 'a', penaltyCount: 1);
      _expectEquals(_eventsOf<PenaltyReachedEvent>(events).length, 1);
    },
    'once per turn mode does not duplicate penalties': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 60));

      engine.tick(const Duration(seconds: 120));
      final snapshot = engine.snapshot();

      _expectParticipant(snapshot, 'a', penaltyCount: 1);
    },
    'every threshold mode records penalties at each threshold': () {
      final engine = TimerEngine.start(
        _config(
          penaltyConfig: const PenaltyConfig(
            repeatMode: PenaltyRepeatMode.everyThreshold,
          ),
        ),
      );
      engine.tick(const Duration(seconds: 60));

      final firstEvents = engine.tick(const Duration(seconds: 60));
      final secondEvents = engine.tick(const Duration(seconds: 60));
      final snapshot = engine.snapshot();

      _expectParticipant(snapshot, 'a', penaltyCount: 2);
      _expectEquals(_eventsOf<PenaltyReachedEvent>(firstEvents).length, 1);
      _expectEquals(_eventsOf<PenaltyReachedEvent>(secondEvents).length, 1);
    },
    'pass turn changes active participant and resets turn state': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 80));

      final events = engine.passTurn();
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.activeParticipantId, 'b');
      _expectEquals(snapshot.currentTurnRemainingSeconds, 60);
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
      _expectParticipant(snapshot, 'a', turnCount: 1);
      _expectEquals(_eventsOf<TurnPassedEvent>(events).length, 1);
    },
    'pause stops time until resume': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 10));

      engine.pause();
      engine.tick(const Duration(seconds: 30));
      var snapshot = engine.snapshot();
      _expectEquals(snapshot.phase, TimerPhase.paused);
      _expectParticipant(snapshot, 'a', totalRemainingSeconds: 290);
      _expectEquals(snapshot.currentTurnRemainingSeconds, 50);

      engine.resume();
      engine.tick(const Duration(seconds: 5));
      snapshot = engine.snapshot();
      _expectEquals(snapshot.phase, TimerPhase.runningNormal);
      _expectParticipant(snapshot, 'a', totalRemainingSeconds: 285);
      _expectEquals(snapshot.currentTurnRemainingSeconds, 45);
    },
    'total time reaching zero enters needs extension': () {
      final engine = TimerEngine.start(_config(aTotal: 3));

      final events = engine.tick(const Duration(seconds: 3));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.needsExtension);
      _expectParticipant(snapshot, 'a', totalRemainingSeconds: 0);
      _expectEquals(_eventsOf<TotalTimeEndedEvent>(events).length, 1);
    },
    'total time ending exactly with turn limit enters needs extension': () {
      final engine = TimerEngine.start(_config(aTotal: 60));

      final events = engine.tick(const Duration(seconds: 60));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.needsExtension);
      _expectEquals(snapshot.currentTurnRemainingSeconds, 0);
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
      _expectParticipant(
        snapshot,
        'a',
        totalRemainingSeconds: 0,
        totalUsedSeconds: 60,
      );
      _expectEquals(_eventsOf<TotalTimeEndedEvent>(events).length, 1);
      _expectEquals(_eventsOf<OvertimeStartedEvent>(events).length, 0);
    },
    'add time from needs extension resumes active participant': () {
      final engine = TimerEngine.start(_config(aTotal: 3));
      engine.tick(const Duration(seconds: 3));

      final events = engine.addTime('a', 60);
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.runningNormal);
      _expectEquals(snapshot.activeParticipantId, 'a');
      _expectEquals(snapshot.currentTurnRemainingSeconds, 60);
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
      _expectParticipant(
        snapshot,
        'a',
        totalAllocatedSeconds: 63,
        totalRemainingSeconds: 60,
      );
      _expectEquals(_eventsOf<TimeAddedEvent>(events).length, 1);
    },
    'multiple turns accumulate participant totals and turn counts': () {
      final engine = TimerEngine.start(_config());
      engine.tick(const Duration(seconds: 20));
      engine.passTurn();
      engine.tick(const Duration(seconds: 15));
      engine.passTurn();

      engine.tick(const Duration(seconds: 25));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.activeParticipantId, 'a');
      _expectEquals(snapshot.currentTurnRemainingSeconds, 35);
      _expectParticipant(
        snapshot,
        'a',
        totalRemainingSeconds: 255,
        totalUsedSeconds: 45,
        turnCount: 1,
      );
      _expectParticipant(
        snapshot,
        'b',
        totalRemainingSeconds: 285,
        totalUsedSeconds: 15,
        turnCount: 1,
      );
    },
    'disabled overtime auto pauses at turn end': () {
      final engine = TimerEngine.start(
        _config(
          overtimeConfig: const OvertimeConfig(
            enabled: false,
            behavior: TurnLimitBehavior.autoPause,
          ),
        ),
      );

      engine.tick(const Duration(seconds: 60));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.paused);
      _expectEquals(snapshot.currentTurnRemainingSeconds, 0);
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
    },
    'auto pause does not keep counting or create penalties': () {
      final engine = TimerEngine.start(
        _config(
          overtimeConfig: const OvertimeConfig(
            enabled: false,
            behavior: TurnLimitBehavior.autoPause,
          ),
        ),
      );
      engine.tick(const Duration(seconds: 60));

      final events = engine.tick(const Duration(seconds: 120));
      final snapshot = engine.snapshot();

      _expectParticipant(
        snapshot,
        'a',
        totalRemainingSeconds: 240,
        totalUsedSeconds: 60,
        overtimeTotalSeconds: 0,
        penaltyCount: 0,
      );
      _expectEquals(snapshot.currentTurnOvertimeSeconds, 0);
      _expectEquals(_eventsOf<PenaltyReachedEvent>(events).length, 0);
    },
    'pass turn from auto pause starts opponent new turn': () {
      final engine = TimerEngine.start(
        _config(
          overtimeConfig: const OvertimeConfig(
            enabled: false,
            behavior: TurnLimitBehavior.autoPause,
          ),
        ),
      );
      engine.tick(const Duration(seconds: 60));

      engine.passTurn();
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.runningNormal);
      _expectEquals(snapshot.activeParticipantId, 'b');
      _expectEquals(snapshot.currentTurnRemainingSeconds, 60);
    },
    'total time ending beats auto pause': () {
      final engine = TimerEngine.start(
        _config(
          aTotal: 30,
          overtimeConfig: const OvertimeConfig(
            enabled: false,
            behavior: TurnLimitBehavior.autoPause,
          ),
        ),
      );

      engine.tick(const Duration(seconds: 30));
      final snapshot = engine.snapshot();

      _expectEquals(snapshot.phase, TimerPhase.needsExtension);
      _expectParticipant(snapshot, 'a', totalRemainingSeconds: 0);
    },
  };

  var failures = 0;
  for (final entry in tests.entries) {
    try {
      entry.value();
      print('PASS ${entry.key}');
    } catch (error, stackTrace) {
      failures += 1;
      print('FAIL ${entry.key}');
      print(error);
      print(stackTrace);
    }
  }

  if (failures > 0) {
    throw StateError('$failures timer engine tests failed.');
  }
}

SessionConfig _config({
  int aTotal = 300,
  int bTotal = 300,
  OvertimeConfig overtimeConfig = const OvertimeConfig(),
  PenaltyConfig penaltyConfig = const PenaltyConfig(),
}) {
  return SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'A',
      totalAllocatedSeconds: aTotal,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'B',
      totalAllocatedSeconds: bTotal,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: overtimeConfig,
    penaltyConfig: penaltyConfig,
    alertConfig: const AlertConfig(warningBeforeSeconds: 10),
  );
}

void _expectParticipant(
  TimerSnapshot snapshot,
  String id, {
  int? totalAllocatedSeconds,
  int? totalRemainingSeconds,
  int? totalUsedSeconds,
  int? turnCount,
  int? overtimeTotalSeconds,
  int? penaltyCount,
}) {
  final participant = snapshot.participants.singleWhere(
    (item) => item.id == id,
  );
  if (totalAllocatedSeconds != null) {
    _expectEquals(participant.totalAllocatedSeconds, totalAllocatedSeconds);
  }
  if (totalRemainingSeconds != null) {
    _expectEquals(participant.totalRemainingSeconds, totalRemainingSeconds);
  }
  if (totalUsedSeconds != null) {
    _expectEquals(participant.totalUsedSeconds, totalUsedSeconds);
  }
  if (turnCount != null) {
    _expectEquals(participant.turnCount, turnCount);
  }
  if (overtimeTotalSeconds != null) {
    _expectEquals(participant.overtimeTotalSeconds, overtimeTotalSeconds);
  }
  if (penaltyCount != null) {
    _expectEquals(participant.penaltyCount, penaltyCount);
  }
}

List<T> _eventsOf<T extends TimerEvent>(List<TimerEvent> events) {
  return events.whereType<T>().toList();
}

void _expectEquals(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
  }
}
