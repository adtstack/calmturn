import 'package:flutter/services.dart';

import 'domain/timer_models.dart';

final class TimerFeedbackCue {
  final String message;
  final bool showOnScreen;
  final bool playSound;
  final bool playHaptic;

  const TimerFeedbackCue({
    required this.message,
    required this.showOnScreen,
    required this.playSound,
    required this.playHaptic,
  });
}

abstract interface class TimerFeedbackSink {
  Future<void> playSound(String soundType);

  Future<void> playHaptic(String hapticStrength);
}

final class PlatformTimerFeedbackSink implements TimerFeedbackSink {
  const PlatformTimerFeedbackSink();

  @override
  Future<void> playSound(String soundType) async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } on Object {
      // Screen feedback remains visible when the platform cannot play sounds.
    }
  }

  @override
  Future<void> playHaptic(String hapticStrength) async {
    try {
      switch (hapticStrength) {
        case 'light':
          await HapticFeedback.lightImpact();
        case 'heavy':
          await HapticFeedback.heavyImpact();
        case 'medium':
        default:
          await HapticFeedback.mediumImpact();
      }
    } on Object {
      // Screen feedback remains visible when haptics are unsupported.
    }
  }
}

final class TimerFeedbackService {
  final TimerFeedbackSink sink;

  const TimerFeedbackService({this.sink = const PlatformTimerFeedbackSink()});

  List<TimerFeedbackCue> cuesFor(
    List<TimerEvent> events,
    SessionConfig config,
  ) {
    return events
        .map((event) => _cueForEvent(event, config))
        .whereType<TimerFeedbackCue>()
        .toList(growable: false);
  }

  Future<void> dispatch(List<TimerFeedbackCue> cues, AlertConfig config) async {
    for (final cue in cues) {
      if (cue.playSound) {
        await sink.playSound(config.soundType);
      }
      if (cue.playHaptic) {
        await sink.playHaptic(config.hapticStrength);
      }
    }
  }

  TimerFeedbackCue? _cueForEvent(TimerEvent event, SessionConfig config) {
    final alert = config.alertConfig;
    final showOvertime = config.overtimeConfig.showOvertime;
    final message = switch (event) {
      TurnWarningEvent(:final remainingSeconds) when alert.turnWarningEnabled =>
        '${remainingSeconds.toString()}초 남았습니다.',
      TotalWarningEvent(:final remainingSeconds)
          when alert.totalWarningEnabled =>
        '전체 시간이 ${remainingSeconds.toString()}초 남았습니다.',
      OvertimeStartedEvent() when alert.overtimeStartAlertEnabled =>
        showOvertime
            ? '오버타임이 시작됐어요. 준비되면 차례를 넘겨주세요.'
            : '차례 시간이 끝났어요. 준비되면 차례를 넘겨주세요.',
      PenaltyReachedEvent(:final penaltyCount) when alert.penaltyAlertEnabled =>
        showOvertime
            ? '오버타임 기준에 도달했어요. 주의 표시 $penaltyCount회 기록'
            : '주의 표시 $penaltyCount회 기록',
      _ => null,
    };

    if (message == null) {
      return null;
    }

    // SDK sound/haptic calls cannot reliably prove delivery across targets,
    // so non-visual alerts keep a screen fallback unless a richer sink exists.
    final nonVisualRequested = alert.soundEnabled || alert.hapticEnabled;
    return TimerFeedbackCue(
      message: message,
      showOnScreen: alert.visualEnabled || nonVisualRequested,
      playSound: alert.soundEnabled,
      playHaptic: alert.hapticEnabled,
    );
  }
}
