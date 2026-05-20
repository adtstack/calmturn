import '../timer/domain/timer_models.dart';

enum TotalTimeMode { same, customPerParticipant }

final class SessionSettingsDraft {
  static const participantAId = 'a';
  static const participantBId = 'b';

  final String participantAName;
  final String participantBName;
  final TotalTimeMode totalTimeMode;
  final int sharedTotalSeconds;
  final int participantATotalSeconds;
  final int participantBTotalSeconds;
  final int turnLimitSeconds;
  final String firstSpeakerId;
  final bool overtimeEnabled;
  final bool showOvertime;
  final bool penaltyEnabled;
  final int penaltyThresholdSeconds;
  final PenaltyRepeatMode penaltyRepeatMode;
  final PenaltyLabelMode penaltyLabelMode;
  final int warningBeforeSeconds;
  final bool turnWarningEnabled;
  final bool totalWarningEnabled;
  final bool overtimeStartAlertEnabled;
  final bool penaltyAlertEnabled;
  final bool visualEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final String soundType;
  final String hapticStrength;

  const SessionSettingsDraft({
    required this.participantAName,
    required this.participantBName,
    required this.totalTimeMode,
    required this.sharedTotalSeconds,
    required this.participantATotalSeconds,
    required this.participantBTotalSeconds,
    required this.turnLimitSeconds,
    required this.firstSpeakerId,
    required this.overtimeEnabled,
    required this.showOvertime,
    required this.penaltyEnabled,
    required this.penaltyThresholdSeconds,
    required this.penaltyRepeatMode,
    required this.penaltyLabelMode,
    required this.warningBeforeSeconds,
    required this.turnWarningEnabled,
    required this.totalWarningEnabled,
    required this.overtimeStartAlertEnabled,
    required this.penaltyAlertEnabled,
    required this.visualEnabled,
    required this.soundEnabled,
    required this.hapticEnabled,
    required this.soundType,
    required this.hapticStrength,
  }) : assert(sharedTotalSeconds > 0),
       assert(participantATotalSeconds > 0),
       assert(participantBTotalSeconds > 0),
       assert(turnLimitSeconds > 0),
       assert(penaltyThresholdSeconds > 0),
       assert(warningBeforeSeconds > 0);

  factory SessionSettingsDraft.defaults() {
    return const SessionSettingsDraft(
      participantAName: '',
      participantBName: '',
      totalTimeMode: TotalTimeMode.same,
      sharedTotalSeconds: 300,
      participantATotalSeconds: 300,
      participantBTotalSeconds: 300,
      turnLimitSeconds: 60,
      firstSpeakerId: participantAId,
      overtimeEnabled: true,
      showOvertime: true,
      penaltyEnabled: true,
      penaltyThresholdSeconds: 60,
      penaltyRepeatMode: PenaltyRepeatMode.oncePerTurn,
      penaltyLabelMode: PenaltyLabelMode.overtimeMark,
      warningBeforeSeconds: 10,
      turnWarningEnabled: true,
      totalWarningEnabled: true,
      overtimeStartAlertEnabled: true,
      penaltyAlertEnabled: true,
      visualEnabled: true,
      soundEnabled: false,
      hapticEnabled: true,
      soundType: 'soft',
      hapticStrength: 'medium',
    );
  }

  int get effectiveParticipantATotalSeconds {
    return totalTimeMode == TotalTimeMode.same
        ? sharedTotalSeconds
        : participantATotalSeconds;
  }

  int get effectiveParticipantBTotalSeconds {
    return totalTimeMode == TotalTimeMode.same
        ? sharedTotalSeconds
        : participantBTotalSeconds;
  }

  SessionConfig toSessionConfig() {
    final overtimeBehavior = overtimeEnabled
        ? TurnLimitBehavior.overtime
        : TurnLimitBehavior.autoPause;

    return SessionConfig(
      participantA: ParticipantConfig(
        id: participantAId,
        name: _cleanName(participantAName, 'Speaker A'),
        totalAllocatedSeconds: effectiveParticipantATotalSeconds,
      ),
      participantB: ParticipantConfig(
        id: participantBId,
        name: _cleanName(participantBName, 'Speaker B'),
        totalAllocatedSeconds: effectiveParticipantBTotalSeconds,
      ),
      turnLimitSeconds: turnLimitSeconds,
      firstSpeakerId: firstSpeakerId,
      overtimeConfig: OvertimeConfig(
        enabled: overtimeEnabled,
        showOvertime: overtimeEnabled && showOvertime,
        behavior: overtimeBehavior,
      ),
      penaltyConfig: PenaltyConfig(
        enabled: penaltyEnabled,
        thresholdSeconds: penaltyThresholdSeconds,
        repeatMode: penaltyRepeatMode,
        labelMode: penaltyLabelMode,
      ),
      alertConfig: AlertConfig(
        warningBeforeSeconds: warningBeforeSeconds,
        turnWarningEnabled: turnWarningEnabled,
        totalWarningEnabled: totalWarningEnabled,
        overtimeStartAlertEnabled: overtimeStartAlertEnabled,
        penaltyAlertEnabled: penaltyAlertEnabled,
        visualEnabled: visualEnabled,
        soundEnabled: soundEnabled,
        hapticEnabled: hapticEnabled,
        soundType: soundType,
        hapticStrength: hapticStrength,
      ),
    );
  }

  SessionSettingsDraft copyWith({
    String? participantAName,
    String? participantBName,
    TotalTimeMode? totalTimeMode,
    int? sharedTotalSeconds,
    int? participantATotalSeconds,
    int? participantBTotalSeconds,
    int? turnLimitSeconds,
    String? firstSpeakerId,
    bool? overtimeEnabled,
    bool? showOvertime,
    bool? penaltyEnabled,
    int? penaltyThresholdSeconds,
    PenaltyRepeatMode? penaltyRepeatMode,
    PenaltyLabelMode? penaltyLabelMode,
    int? warningBeforeSeconds,
    bool? turnWarningEnabled,
    bool? totalWarningEnabled,
    bool? overtimeStartAlertEnabled,
    bool? penaltyAlertEnabled,
    bool? visualEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    String? soundType,
    String? hapticStrength,
  }) {
    return SessionSettingsDraft(
      participantAName: participantAName ?? this.participantAName,
      participantBName: participantBName ?? this.participantBName,
      totalTimeMode: totalTimeMode ?? this.totalTimeMode,
      sharedTotalSeconds: sharedTotalSeconds ?? this.sharedTotalSeconds,
      participantATotalSeconds:
          participantATotalSeconds ?? this.participantATotalSeconds,
      participantBTotalSeconds:
          participantBTotalSeconds ?? this.participantBTotalSeconds,
      turnLimitSeconds: turnLimitSeconds ?? this.turnLimitSeconds,
      firstSpeakerId: firstSpeakerId ?? this.firstSpeakerId,
      overtimeEnabled: overtimeEnabled ?? this.overtimeEnabled,
      showOvertime: showOvertime ?? this.showOvertime,
      penaltyEnabled: penaltyEnabled ?? this.penaltyEnabled,
      penaltyThresholdSeconds:
          penaltyThresholdSeconds ?? this.penaltyThresholdSeconds,
      penaltyRepeatMode: penaltyRepeatMode ?? this.penaltyRepeatMode,
      penaltyLabelMode: penaltyLabelMode ?? this.penaltyLabelMode,
      warningBeforeSeconds: warningBeforeSeconds ?? this.warningBeforeSeconds,
      turnWarningEnabled: turnWarningEnabled ?? this.turnWarningEnabled,
      totalWarningEnabled: totalWarningEnabled ?? this.totalWarningEnabled,
      overtimeStartAlertEnabled:
          overtimeStartAlertEnabled ?? this.overtimeStartAlertEnabled,
      penaltyAlertEnabled: penaltyAlertEnabled ?? this.penaltyAlertEnabled,
      visualEnabled: visualEnabled ?? this.visualEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundType: soundType ?? this.soundType,
      hapticStrength: hapticStrength ?? this.hapticStrength,
    );
  }
}

String _cleanName(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
