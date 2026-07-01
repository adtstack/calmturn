import '../timer/domain/timer_models.dart';

enum TotalTimeMode { same, customPerParticipant }

const invalidTurnLimitMessage = '턴 제한은 전체 시간보다 길 수 없어요.';
const invalidOvertimeWindowMessage = '오버타임을 쓰려면 턴 제한이 전체 시간보다 짧아야 해요.';
const invalidPenaltyThresholdMessage = '내부 기록 기준은 가능한 오버타임보다 길 수 없어요.';
const invalidWarningBeforeMessage = '알림 시점은 턴 제한과 전체 시간보다 짧아야 해요.';
const invalidAlertDeliveryMessage = '알림 방식이 모두 꺼져 있어요.';
const invalidAlertTargetMessage = '알림 대상이 모두 꺼져 있어요.';
const invalidTotalTimeRangeMessage = '전체 시간은 1분부터 240분까지 입력할 수 있어요.';
const invalidTurnLimitRangeMessage = '턴 제한은 1초부터 1분까지 입력할 수 있어요.';
const invalidSessionConfigMessage = '저장된 설정을 다시 확인해야 해요.';

const minTotalMinutes = 1;
const maxTotalMinutes = 240;
const minTurnLimitSeconds = 1;
const maxTurnLimitSeconds = 60;

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
  final bool turnDangerFlashEnabled;
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
    required this.turnDangerFlashEnabled,
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
      sharedTotalSeconds: 600,
      participantATotalSeconds: 600,
      participantBTotalSeconds: 600,
      turnLimitSeconds: 30,
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
      turnDangerFlashEnabled: true,
      soundEnabled: false,
      hapticEnabled: true,
      soundType: 'soft',
      hapticStrength: 'medium',
    );
  }

  factory SessionSettingsDraft.fromSessionConfig(SessionConfig config) {
    final sameTotal =
        config.participantA.totalAllocatedSeconds ==
        config.participantB.totalAllocatedSeconds;
    return SessionSettingsDraft.defaults().copyWith(
      participantAName: config.participantA.name,
      participantBName: config.participantB.name,
      totalTimeMode: sameTotal
          ? TotalTimeMode.same
          : TotalTimeMode.customPerParticipant,
      sharedTotalSeconds: sameTotal
          ? config.participantA.totalAllocatedSeconds
          : SessionSettingsDraft.defaults().sharedTotalSeconds,
      participantATotalSeconds: config.participantA.totalAllocatedSeconds,
      participantBTotalSeconds: config.participantB.totalAllocatedSeconds,
      turnLimitSeconds: config.turnLimitSeconds,
      firstSpeakerId: config.firstSpeakerId,
      overtimeEnabled: config.overtimeConfig.enabled,
      showOvertime: config.overtimeConfig.showOvertime,
      penaltyEnabled: config.penaltyConfig.enabled,
      penaltyThresholdSeconds: config.penaltyConfig.thresholdSeconds,
      penaltyRepeatMode: config.penaltyConfig.repeatMode,
      penaltyLabelMode: config.penaltyConfig.labelMode,
      warningBeforeSeconds: config.alertConfig.warningBeforeSeconds,
      turnWarningEnabled: config.alertConfig.turnWarningEnabled,
      totalWarningEnabled: config.alertConfig.totalWarningEnabled,
      overtimeStartAlertEnabled: config.alertConfig.overtimeStartAlertEnabled,
      penaltyAlertEnabled: config.alertConfig.penaltyAlertEnabled,
      visualEnabled: config.alertConfig.visualEnabled,
      turnDangerFlashEnabled: config.alertConfig.turnDangerFlashEnabled,
      soundEnabled: config.alertConfig.soundEnabled,
      hapticEnabled: config.alertConfig.hapticEnabled,
      soundType: config.alertConfig.soundType,
      hapticStrength: config.alertConfig.hapticStrength,
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
    final effectivePenaltyEnabled = overtimeEnabled && penaltyEnabled;
    final effectiveOvertimeStartAlertEnabled =
        overtimeEnabled && overtimeStartAlertEnabled;
    final effectivePenaltyAlertEnabled =
        effectivePenaltyEnabled && penaltyAlertEnabled;

    return SessionConfig(
      participantA: ParticipantConfig(
        id: participantAId,
        name: _cleanName(participantAName),
        totalAllocatedSeconds: effectiveParticipantATotalSeconds,
      ),
      participantB: ParticipantConfig(
        id: participantBId,
        name: _cleanName(participantBName),
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
        enabled: effectivePenaltyEnabled,
        thresholdSeconds: penaltyThresholdSeconds,
        repeatMode: penaltyRepeatMode,
        labelMode: penaltyLabelMode,
      ),
      alertConfig: AlertConfig(
        warningBeforeSeconds: warningBeforeSeconds,
        turnWarningEnabled: _effectiveTurnWarningEnabled(
          turnWarningEnabled: turnWarningEnabled,
          warningBeforeSeconds: warningBeforeSeconds,
          turnLimitSeconds: turnLimitSeconds,
        ),
        totalWarningEnabled: totalWarningEnabled,
        overtimeStartAlertEnabled: effectiveOvertimeStartAlertEnabled,
        penaltyAlertEnabled: effectivePenaltyAlertEnabled,
        visualEnabled: visualEnabled,
        turnDangerFlashEnabled: turnDangerFlashEnabled,
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
    bool? turnDangerFlashEnabled,
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
      turnDangerFlashEnabled:
          turnDangerFlashEnabled ?? this.turnDangerFlashEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      soundType: soundType ?? this.soundType,
      hapticStrength: hapticStrength ?? this.hapticStrength,
    );
  }
}

String _cleanName(String value) {
  final trimmed = value.trim();
  return trimmed;
}

String? validateSessionSettingsDraft(SessionSettingsDraft draft) {
  return _validateSessionSettings(
    participantAId: SessionSettingsDraft.participantAId,
    participantBId: SessionSettingsDraft.participantBId,
    participantATotalSeconds: draft.effectiveParticipantATotalSeconds,
    participantBTotalSeconds: draft.effectiveParticipantBTotalSeconds,
    turnLimitSeconds: draft.turnLimitSeconds,
    firstSpeakerId: draft.firstSpeakerId,
    overtimeEnabled: draft.overtimeEnabled,
    showOvertime: draft.overtimeEnabled && draft.showOvertime,
    overtimeBehavior: draft.overtimeEnabled
        ? TurnLimitBehavior.overtime
        : TurnLimitBehavior.autoPause,
    penaltyEnabled: draft.overtimeEnabled && draft.penaltyEnabled,
    penaltyThresholdSeconds: draft.penaltyThresholdSeconds,
    warningBeforeSeconds: draft.warningBeforeSeconds,
    turnWarningEnabled: draft.turnWarningEnabled,
    totalWarningEnabled: draft.totalWarningEnabled,
    overtimeStartAlertEnabled:
        draft.overtimeEnabled && draft.overtimeStartAlertEnabled,
    penaltyAlertEnabled:
        draft.overtimeEnabled &&
        draft.penaltyEnabled &&
        draft.penaltyAlertEnabled,
    visualEnabled: draft.visualEnabled,
    turnDangerFlashEnabled: draft.turnDangerFlashEnabled,
    soundEnabled: draft.soundEnabled,
    hapticEnabled: draft.hapticEnabled,
  );
}

String? validateSessionConfig(SessionConfig config) {
  final identityMessage = _validateSessionIdentities(config);
  if (identityMessage != null) {
    return identityMessage;
  }

  if (!config.overtimeConfig.enabled &&
      (config.overtimeConfig.showOvertime ||
          config.penaltyConfig.enabled ||
          config.alertConfig.overtimeStartAlertEnabled ||
          config.alertConfig.penaltyAlertEnabled)) {
    return invalidSessionConfigMessage;
  }

  return _validateSessionSettings(
    participantAId: config.participantA.id,
    participantBId: config.participantB.id,
    participantATotalSeconds: config.participantA.totalAllocatedSeconds,
    participantBTotalSeconds: config.participantB.totalAllocatedSeconds,
    turnLimitSeconds: config.turnLimitSeconds,
    firstSpeakerId: config.firstSpeakerId,
    overtimeEnabled: config.overtimeConfig.enabled,
    showOvertime: config.overtimeConfig.showOvertime,
    overtimeBehavior: config.overtimeConfig.behavior,
    penaltyEnabled: config.penaltyConfig.enabled,
    penaltyThresholdSeconds: config.penaltyConfig.thresholdSeconds,
    warningBeforeSeconds: config.alertConfig.warningBeforeSeconds,
    turnWarningEnabled: config.alertConfig.turnWarningEnabled,
    totalWarningEnabled: config.alertConfig.totalWarningEnabled,
    overtimeStartAlertEnabled: config.alertConfig.overtimeStartAlertEnabled,
    penaltyAlertEnabled: config.alertConfig.penaltyAlertEnabled,
    visualEnabled: config.alertConfig.visualEnabled,
    turnDangerFlashEnabled: config.alertConfig.turnDangerFlashEnabled,
    soundEnabled: config.alertConfig.soundEnabled,
    hapticEnabled: config.alertConfig.hapticEnabled,
  );
}

String? _validateSessionSettings({
  required String participantAId,
  required String participantBId,
  required int participantATotalSeconds,
  required int participantBTotalSeconds,
  required int turnLimitSeconds,
  required String firstSpeakerId,
  required bool overtimeEnabled,
  required bool showOvertime,
  required TurnLimitBehavior overtimeBehavior,
  required bool penaltyEnabled,
  required int penaltyThresholdSeconds,
  required int warningBeforeSeconds,
  required bool turnWarningEnabled,
  required bool totalWarningEnabled,
  required bool overtimeStartAlertEnabled,
  required bool penaltyAlertEnabled,
  required bool visualEnabled,
  required bool turnDangerFlashEnabled,
  required bool soundEnabled,
  required bool hapticEnabled,
}) {
  final totalRangeMessage = _validateTotalSeconds(participantATotalSeconds);
  if (totalRangeMessage != null) {
    return totalRangeMessage;
  }

  final otherTotalRangeMessage = _validateTotalSeconds(
    participantBTotalSeconds,
  );
  if (otherTotalRangeMessage != null) {
    return otherTotalRangeMessage;
  }

  final turnRangeMessage = _validateTurnLimitSeconds(turnLimitSeconds);
  if (turnRangeMessage != null) {
    return turnRangeMessage;
  }

  if (warningBeforeSeconds <= 0 || penaltyThresholdSeconds <= 0) {
    return invalidSessionConfigMessage;
  }

  if (participantAId.isEmpty ||
      participantBId.isEmpty ||
      participantAId == participantBId ||
      (firstSpeakerId != participantAId && firstSpeakerId != participantBId)) {
    return invalidSessionConfigMessage;
  }

  if (!overtimeEnabled && showOvertime) {
    return invalidSessionConfigMessage;
  }

  if (overtimeEnabled && overtimeBehavior != TurnLimitBehavior.overtime) {
    return invalidSessionConfigMessage;
  }

  if (!overtimeEnabled && overtimeBehavior == TurnLimitBehavior.overtime) {
    return invalidSessionConfigMessage;
  }

  if (!overtimeEnabled && penaltyEnabled) {
    return invalidSessionConfigMessage;
  }

  if (!overtimeEnabled && (overtimeStartAlertEnabled || penaltyAlertEnabled)) {
    return invalidSessionConfigMessage;
  }

  final shortestTotal = participantATotalSeconds <= participantBTotalSeconds
      ? participantATotalSeconds
      : participantBTotalSeconds;

  if (turnLimitSeconds > shortestTotal) {
    return invalidTurnLimitMessage;
  }

  if (overtimeEnabled && turnLimitSeconds >= shortestTotal) {
    return invalidOvertimeWindowMessage;
  }

  final effectiveTurnWarningEnabled = _effectiveTurnWarningEnabled(
    turnWarningEnabled: turnWarningEnabled,
    warningBeforeSeconds: warningBeforeSeconds,
    turnLimitSeconds: turnLimitSeconds,
  );

  if (totalWarningEnabled && warningBeforeSeconds >= shortestTotal) {
    return invalidWarningBeforeMessage;
  }

  final effectivePenaltyEnabled = overtimeEnabled && penaltyEnabled;
  if (effectivePenaltyEnabled) {
    final maxPossibleOvertimeSeconds = shortestTotal - turnLimitSeconds;
    if (maxPossibleOvertimeSeconds <= 0 ||
        penaltyThresholdSeconds > maxPossibleOvertimeSeconds) {
      return invalidPenaltyThresholdMessage;
    }
  }

  final activeAlertTargetCount = _activeAlertTargetCount(
    overtimeEnabled: overtimeEnabled,
    penaltyEnabled: effectivePenaltyEnabled,
    turnWarningEnabled: effectiveTurnWarningEnabled,
    totalWarningEnabled: totalWarningEnabled,
    overtimeStartAlertEnabled: overtimeStartAlertEnabled,
    penaltyAlertEnabled: penaltyAlertEnabled,
    turnDangerFlashEnabled: turnDangerFlashEnabled,
  );
  final activeAlertDeliveryCount = _activeAlertDeliveryCount(
    visualEnabled: visualEnabled,
    turnDangerFlashEnabled: turnDangerFlashEnabled,
    soundEnabled: soundEnabled,
    hapticEnabled: hapticEnabled,
  );

  if (activeAlertTargetCount > 0 && activeAlertDeliveryCount == 0) {
    return invalidAlertDeliveryMessage;
  }

  if (activeAlertTargetCount == 0 && activeAlertDeliveryCount > 0) {
    return invalidAlertTargetMessage;
  }

  return null;
}

bool _effectiveTurnWarningEnabled({
  required bool turnWarningEnabled,
  required int warningBeforeSeconds,
  required int turnLimitSeconds,
}) {
  return turnWarningEnabled && warningBeforeSeconds < turnLimitSeconds;
}

String? _validateSessionIdentities(SessionConfig config) {
  if (config.participantA.id.isEmpty || config.participantB.id.isEmpty) {
    return invalidSessionConfigMessage;
  }

  if (config.participantA.id == config.participantB.id) {
    return invalidSessionConfigMessage;
  }

  if (config.firstSpeakerId != config.participantA.id &&
      config.firstSpeakerId != config.participantB.id) {
    return invalidSessionConfigMessage;
  }

  return null;
}

String? _validateTotalSeconds(int seconds) {
  if (seconds < minTotalMinutes * 60 ||
      seconds > maxTotalMinutes * 60 ||
      seconds % 60 != 0) {
    return invalidTotalTimeRangeMessage;
  }
  return null;
}

String? _validateTurnLimitSeconds(int seconds) {
  if (seconds < minTurnLimitSeconds || seconds > maxTurnLimitSeconds) {
    return invalidTurnLimitRangeMessage;
  }
  return null;
}

int _activeAlertTargetCount({
  required bool overtimeEnabled,
  required bool penaltyEnabled,
  required bool turnWarningEnabled,
  required bool totalWarningEnabled,
  required bool overtimeStartAlertEnabled,
  required bool penaltyAlertEnabled,
  required bool turnDangerFlashEnabled,
}) {
  var count = 0;
  if (turnWarningEnabled) {
    count += 1;
  }
  if (totalWarningEnabled) {
    count += 1;
  }
  if (overtimeEnabled && overtimeStartAlertEnabled) {
    count += 1;
  }
  if (overtimeEnabled && penaltyEnabled && penaltyAlertEnabled) {
    count += 1;
  }
  if (turnDangerFlashEnabled) {
    count += 1;
  }
  return count;
}

int _activeAlertDeliveryCount({
  required bool visualEnabled,
  required bool turnDangerFlashEnabled,
  required bool soundEnabled,
  required bool hapticEnabled,
}) {
  var count = 0;
  if (visualEnabled) {
    count += 1;
  }
  if (turnDangerFlashEnabled) {
    count += 1;
  }
  if (soundEnabled) {
    count += 1;
  }
  if (hapticEnabled) {
    count += 1;
  }
  return count;
}
