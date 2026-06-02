import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/features/timer/timer_feedback.dart';

Future<void> main() async {
  final tests = <String, Future<void> Function()>{
    'feedback cues carry screen sound and haptic alert settings': () async {
      const config = SessionConfig(
        participantA: ParticipantConfig(
          id: 'a',
          name: 'A',
          totalAllocatedSeconds: 300,
        ),
        participantB: ParticipantConfig(
          id: 'b',
          name: 'B',
          totalAllocatedSeconds: 300,
        ),
        turnLimitSeconds: 60,
        firstSpeakerId: 'a',
        overtimeConfig: OvertimeConfig(),
        penaltyConfig: PenaltyConfig(),
        alertConfig: AlertConfig(
          warningBeforeSeconds: 10,
          visualEnabled: false,
          soundEnabled: true,
          hapticEnabled: true,
          soundType: 'soft',
          hapticStrength: 'heavy',
        ),
      );
      final sink = _RecordingFeedbackSink();
      final service = TimerFeedbackService(sink: sink);

      final cues = service.cuesFor(const [
        TurnWarningEvent(participantId: 'a', remainingSeconds: 10),
      ], config);
      await service.dispatch(cues, config.alertConfig);

      _expectEquals(cues.length, 1);
      _expectEquals(cues.single.message, '10초 남았습니다.');
      _expectEquals(cues.single.showOnScreen, true);
      _expectEquals(cues.single.playSound, true);
      _expectEquals(cues.single.playHaptic, true);
      _expectList(sink.sounds, ['soft'], 'sound dispatch');
      _expectList(sink.haptics, ['heavy'], 'haptic dispatch');
    },
    'disabled alert channels do not dispatch sound or haptic feedback':
        () async {
          const config = SessionConfig(
            participantA: ParticipantConfig(
              id: 'a',
              name: 'A',
              totalAllocatedSeconds: 300,
            ),
            participantB: ParticipantConfig(
              id: 'b',
              name: 'B',
              totalAllocatedSeconds: 300,
            ),
            turnLimitSeconds: 60,
            firstSpeakerId: 'a',
            overtimeConfig: OvertimeConfig(),
            penaltyConfig: PenaltyConfig(),
            alertConfig: AlertConfig(
              warningBeforeSeconds: 10,
              visualEnabled: true,
              soundEnabled: false,
              hapticEnabled: false,
            ),
          );
          final sink = _RecordingFeedbackSink();
          final service = TimerFeedbackService(sink: sink);

          final cues = service.cuesFor(const [
            PenaltyReachedEvent(
              participantId: 'a',
              overtimeSeconds: 60,
              penaltyCount: 1,
            ),
          ], config);
          await service.dispatch(cues, config.alertConfig);

          _expectEquals(cues.length, 1);
          _expectEquals(cues.single.showOnScreen, true);
          _expectEquals(cues.single.playSound, false);
          _expectEquals(cues.single.playHaptic, false);
          _expectList(sink.sounds, const [], 'sound dispatch');
          _expectList(sink.haptics, const [], 'haptic dispatch');
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
      throw StateError('timer_feedback_test failed');
    }
  }
}

final class _RecordingFeedbackSink implements TimerFeedbackSink {
  final List<String> sounds = [];
  final List<String> haptics = [];

  @override
  Future<void> playSound(String soundType) async {
    sounds.add(soundType);
  }

  @override
  Future<void> playHaptic(String hapticStrength) async {
    haptics.add(hapticStrength);
  }
}

void _expectEquals(Object? actual, Object? expected) {
  if (actual != expected) {
    throw StateError('Expected <$expected>, got <$actual>.');
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
