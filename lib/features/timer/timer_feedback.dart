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
        '${remainingSeconds.toString()} seconds left in this turn.',
      TotalWarningEvent(:final remainingSeconds)
          when alert.totalWarningEnabled =>
        '${remainingSeconds.toString()} seconds of total time left.',
      OvertimeStartedEvent() when alert.overtimeStartAlertEnabled =>
        showOvertime
            ? 'Overtime started. Pass the turn when ready.'
            : 'Turn limit reached. Pass the turn when ready.',
      PenaltyReachedEvent(:final penaltyCount) when alert.penaltyAlertEnabled =>
        showOvertime
            ? 'Overtime mark reached. Mark $penaltyCount recorded.'
            : 'Mark $penaltyCount recorded.',
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
