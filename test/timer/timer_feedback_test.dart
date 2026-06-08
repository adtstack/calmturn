import 'package:calmturn/features/timer/domain/timer_models.dart';
import 'package:calmturn/features/timer/timer_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feedback cues carry screen sound and haptic alert settings', () async {
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

    expect(cues, hasLength(1));
    expect(cues.single.message, '10초 남았습니다.');
    expect(cues.single.showOnScreen, isTrue);
    expect(cues.single.playSound, isTrue);
    expect(cues.single.playHaptic, isTrue);
    expect(sink.sounds, ['soft']);
    expect(sink.haptics, ['heavy']);
  });

  test(
    'disabled alert channels do not dispatch sound or haptic feedback',
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
        OvertimeStartedEvent(participantId: 'a'),
      ], config);
      await service.dispatch(cues, config.alertConfig);

      expect(cues, hasLength(1));
      expect(cues.single.message, '오버타임이 시작됐어요. 준비되면 차례를 넘겨주세요.');
      expect(cues.single.showOnScreen, isTrue);
      expect(cues.single.playSound, isFalse);
      expect(cues.single.playHaptic, isFalse);
      expect(sink.sounds, isEmpty);
      expect(sink.haptics, isEmpty);
    },
  );
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
