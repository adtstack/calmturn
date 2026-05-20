enum TurnLimitBehavior { overtime, autoSwitch, autoPause }

enum PenaltyRepeatMode { oncePerTurn, everyThreshold }

enum PenaltyLabelMode { overtimeMark, warningMark, penalty }

enum TimerPhase {
  draft,
  waitingConsent,
  runningNormal,
  runningOvertime,
  paused,
  needsExtension,
  finished,
}

final class ParticipantConfig {
  final String id;
  final String name;
  final int totalAllocatedSeconds;

  const ParticipantConfig({
    required this.id,
    required this.name,
    required this.totalAllocatedSeconds,
  }) : assert(totalAllocatedSeconds > 0);
}

final class Participant {
  final String id;
  final String name;
  final int totalAllocatedSeconds;
  final int totalRemainingSeconds;
  final int totalUsedSeconds;
  final int turnCount;
  final int overtimeTotalSeconds;
  final int penaltyCount;

  const Participant({
    required this.id,
    required this.name,
    required this.totalAllocatedSeconds,
    required this.totalRemainingSeconds,
    required this.totalUsedSeconds,
    required this.turnCount,
    required this.overtimeTotalSeconds,
    required this.penaltyCount,
  });

  factory Participant.fromConfig(ParticipantConfig config) {
    return Participant(
      id: config.id,
      name: config.name,
      totalAllocatedSeconds: config.totalAllocatedSeconds,
      totalRemainingSeconds: config.totalAllocatedSeconds,
      totalUsedSeconds: 0,
      turnCount: 0,
      overtimeTotalSeconds: 0,
      penaltyCount: 0,
    );
  }

  Participant copyWith({
    String? id,
    String? name,
    int? totalAllocatedSeconds,
    int? totalRemainingSeconds,
    int? totalUsedSeconds,
    int? turnCount,
    int? overtimeTotalSeconds,
    int? penaltyCount,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAllocatedSeconds:
          totalAllocatedSeconds ?? this.totalAllocatedSeconds,
      totalRemainingSeconds:
          totalRemainingSeconds ?? this.totalRemainingSeconds,
      totalUsedSeconds: totalUsedSeconds ?? this.totalUsedSeconds,
      turnCount: turnCount ?? this.turnCount,
      overtimeTotalSeconds: overtimeTotalSeconds ?? this.overtimeTotalSeconds,
      penaltyCount: penaltyCount ?? this.penaltyCount,
    );
  }
}

final class SessionConfig {
  final ParticipantConfig participantA;
  final ParticipantConfig participantB;
  final int turnLimitSeconds;
  final String firstSpeakerId;
  final OvertimeConfig overtimeConfig;
  final PenaltyConfig penaltyConfig;
  final AlertConfig alertConfig;
  final bool requireBothConsentForExtension;

  const SessionConfig({
    required this.participantA,
    required this.participantB,
    required this.turnLimitSeconds,
    required this.firstSpeakerId,
    required this.overtimeConfig,
    required this.penaltyConfig,
    required this.alertConfig,
    this.requireBothConsentForExtension = true,
  }) : assert(turnLimitSeconds > 0);
}

final class OvertimeConfig {
  final bool enabled;
  final bool showOvertime;
  final TurnLimitBehavior behavior;

  const OvertimeConfig({
    this.enabled = true,
    this.showOvertime = true,
    this.behavior = TurnLimitBehavior.overtime,
  });
}

final class PenaltyConfig {
  final bool enabled;
  final int thresholdSeconds;
  final PenaltyRepeatMode repeatMode;
  final PenaltyLabelMode labelMode;

  const PenaltyConfig({
    this.enabled = true,
    this.thresholdSeconds = 60,
    this.repeatMode = PenaltyRepeatMode.oncePerTurn,
    this.labelMode = PenaltyLabelMode.overtimeMark,
  }) : assert(thresholdSeconds > 0);
}

final class AlertConfig {
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

  const AlertConfig({
    this.warningBeforeSeconds = 10,
    this.turnWarningEnabled = true,
    this.totalWarningEnabled = true,
    this.overtimeStartAlertEnabled = true,
    this.penaltyAlertEnabled = true,
    this.visualEnabled = true,
    this.soundEnabled = false,
    this.hapticEnabled = true,
    this.soundType = 'soft',
    this.hapticStrength = 'medium',
  }) : assert(warningBeforeSeconds > 0);
}

final class TimerSnapshot {
  final TimerPhase phase;
  final List<Participant> participants;
  final String activeParticipantId;
  final int currentTurnRemainingSeconds;
  final int currentTurnOvertimeSeconds;
  final bool hasPenaltyInCurrentTurn;
  final Set<String> firedAlertKeys;

  const TimerSnapshot({
    required this.phase,
    required this.participants,
    required this.activeParticipantId,
    required this.currentTurnRemainingSeconds,
    required this.currentTurnOvertimeSeconds,
    required this.hasPenaltyInCurrentTurn,
    required this.firedAlertKeys,
  });

  TimerSnapshot copyWith({
    TimerPhase? phase,
    List<Participant>? participants,
    String? activeParticipantId,
    int? currentTurnRemainingSeconds,
    int? currentTurnOvertimeSeconds,
    bool? hasPenaltyInCurrentTurn,
    Set<String>? firedAlertKeys,
  }) {
    return TimerSnapshot(
      phase: phase ?? this.phase,
      participants: List.unmodifiable(participants ?? this.participants),
      activeParticipantId: activeParticipantId ?? this.activeParticipantId,
      currentTurnRemainingSeconds:
          currentTurnRemainingSeconds ?? this.currentTurnRemainingSeconds,
      currentTurnOvertimeSeconds:
          currentTurnOvertimeSeconds ?? this.currentTurnOvertimeSeconds,
      hasPenaltyInCurrentTurn:
          hasPenaltyInCurrentTurn ?? this.hasPenaltyInCurrentTurn,
      firedAlertKeys: Set.unmodifiable(firedAlertKeys ?? this.firedAlertKeys),
    );
  }
}

sealed class TimerEvent {
  const TimerEvent();
}

final class TurnWarningEvent extends TimerEvent {
  final String participantId;
  final int remainingSeconds;

  const TurnWarningEvent({
    required this.participantId,
    required this.remainingSeconds,
  });
}

final class TotalWarningEvent extends TimerEvent {
  final String participantId;
  final int remainingSeconds;

  const TotalWarningEvent({
    required this.participantId,
    required this.remainingSeconds,
  });
}

final class OvertimeStartedEvent extends TimerEvent {
  final String participantId;

  const OvertimeStartedEvent({required this.participantId});
}

final class PenaltyReachedEvent extends TimerEvent {
  final String participantId;
  final int overtimeSeconds;
  final int penaltyCount;

  const PenaltyReachedEvent({
    required this.participantId,
    required this.overtimeSeconds,
    required this.penaltyCount,
  });
}

final class TurnPassedEvent extends TimerEvent {
  final String fromParticipantId;
  final String toParticipantId;

  const TurnPassedEvent({
    required this.fromParticipantId,
    required this.toParticipantId,
  });
}

final class TotalTimeEndedEvent extends TimerEvent {
  final String participantId;

  const TotalTimeEndedEvent({required this.participantId});
}

final class SessionPausedEvent extends TimerEvent {
  final String participantId;

  const SessionPausedEvent({required this.participantId});
}

final class SessionFinishedEvent extends TimerEvent {
  const SessionFinishedEvent();
}

final class TimeAddedEvent extends TimerEvent {
  final String participantId;
  final int addedSeconds;

  const TimeAddedEvent({
    required this.participantId,
    required this.addedSeconds,
  });
}
