import 'dart:math';

import 'timer_models.dart';

final class TimerEngine {
  final SessionConfig _config;
  TimerSnapshot _snapshot;
  TimerPhase? _resumePhase;
  int _turnId = 0;
  int _lastPenaltyIndexInCurrentTurn = 0;

  TimerEngine._(this._config, this._snapshot);

  factory TimerEngine.start(SessionConfig config) {
    _validateConfig(config);
    final participants = List<Participant>.unmodifiable([
      Participant.fromConfig(config.participantA),
      Participant.fromConfig(config.participantB),
    ]);
    final active = participants.singleWhere(
      (participant) => participant.id == config.firstSpeakerId,
    );

    return TimerEngine._(
      config,
      TimerSnapshot(
        phase: TimerPhase.runningNormal,
        participants: participants,
        activeParticipantId: active.id,
        currentTurnRemainingSeconds: min(
          config.turnLimitSeconds,
          active.totalRemainingSeconds,
        ),
        currentTurnOvertimeSeconds: 0,
        hasPenaltyInCurrentTurn: false,
        firedAlertKeys: const {},
      ),
    );
  }

  TimerSnapshot snapshot() => _snapshot;

  bool get canResume {
    return _snapshot.phase == TimerPhase.paused && _resumePhase != null;
  }

  List<TimerEvent> tick(Duration elapsed) {
    final seconds = elapsed.inSeconds;
    if (seconds <= 0) {
      return const [];
    }

    final events = <TimerEvent>[];
    for (var second = 0; second < seconds; second += 1) {
      switch (_snapshot.phase) {
        case TimerPhase.runningNormal:
          _tickNormal(events);
        case TimerPhase.runningOvertime:
          _tickOvertime(events);
        case TimerPhase.draft:
        case TimerPhase.waitingConsent:
        case TimerPhase.paused:
        case TimerPhase.needsExtension:
        case TimerPhase.finished:
          return events;
      }
    }
    return events;
  }

  List<TimerEvent> passTurn() {
    if (_snapshot.phase == TimerPhase.finished ||
        _snapshot.phase == TimerPhase.needsExtension) {
      return const [];
    }

    final previous = _activeParticipant;
    final next = _otherParticipant(previous.id);
    if (next.totalRemainingSeconds <= 0) {
      _enterNeedsExtension(next.id, null);
      return [TotalTimeEndedEvent(participantId: next.id)];
    }

    final updatedPrevious = previous.copyWith(
      turnCount: previous.turnCount + 1,
    );
    _turnId += 1;
    _lastPenaltyIndexInCurrentTurn = 0;
    _resumePhase = null;
    _snapshot = _snapshot.copyWith(
      phase: TimerPhase.runningNormal,
      participants: _replaceParticipant(updatedPrevious),
      activeParticipantId: next.id,
      currentTurnRemainingSeconds: min(
        _config.turnLimitSeconds,
        next.totalRemainingSeconds,
      ),
      currentTurnOvertimeSeconds: 0,
      hasPenaltyInCurrentTurn: false,
    );

    return [
      TurnPassedEvent(fromParticipantId: previous.id, toParticipantId: next.id),
    ];
  }

  List<TimerEvent> pause() {
    if (_snapshot.phase != TimerPhase.runningNormal &&
        _snapshot.phase != TimerPhase.runningOvertime) {
      return const [];
    }

    _resumePhase = _snapshot.phase;
    _snapshot = _snapshot.copyWith(phase: TimerPhase.paused);
    return [SessionPausedEvent(participantId: _snapshot.activeParticipantId)];
  }

  List<TimerEvent> resume() {
    final phase = _resumePhase;
    if (_snapshot.phase != TimerPhase.paused || phase == null) {
      return const [];
    }

    _resumePhase = null;
    _snapshot = _snapshot.copyWith(phase: phase);
    return const [];
  }

  List<TimerEvent> finish() {
    if (_snapshot.phase == TimerPhase.finished) {
      return const [];
    }

    _resumePhase = null;
    _snapshot = _snapshot.copyWith(phase: TimerPhase.finished);
    return const [SessionFinishedEvent()];
  }

  List<TimerEvent> addTime(String participantId, int seconds) {
    if (seconds <= 0) {
      throw ArgumentError.value(seconds, 'seconds', 'must be greater than 0');
    }

    final participant = _participantById(participantId);
    final updated = participant.copyWith(
      totalAllocatedSeconds: participant.totalAllocatedSeconds + seconds,
      totalRemainingSeconds: participant.totalRemainingSeconds + seconds,
    );
    _snapshot = _snapshot.copyWith(participants: _replaceParticipant(updated));

    if (_snapshot.phase == TimerPhase.needsExtension &&
        participantId == _snapshot.activeParticipantId) {
      _snapshot = _snapshot.copyWith(
        phase: TimerPhase.runningNormal,
        currentTurnRemainingSeconds: min(
          _config.turnLimitSeconds,
          updated.totalRemainingSeconds,
        ),
        currentTurnOvertimeSeconds: 0,
        hasPenaltyInCurrentTurn: false,
      );
    }

    return [
      TimeAddedEvent(participantId: participantId, addedSeconds: seconds),
    ];
  }

  void _tickNormal(List<TimerEvent> events) {
    final active = _activeParticipant;
    final updated = active.copyWith(
      totalRemainingSeconds: max(0, active.totalRemainingSeconds - 1),
      totalUsedSeconds: active.totalUsedSeconds + 1,
    );
    _snapshot = _snapshot.copyWith(
      participants: _replaceParticipant(updated),
      currentTurnRemainingSeconds: max(
        0,
        _snapshot.currentTurnRemainingSeconds - 1,
      ),
    );

    _emitWarnings(events);
    if (updated.totalRemainingSeconds == 0) {
      _enterNeedsExtension(updated.id, events);
      return;
    }

    if (_snapshot.currentTurnRemainingSeconds == 0) {
      _handleTurnLimitEnded(events);
    }
  }

  void _tickOvertime(List<TimerEvent> events) {
    final active = _activeParticipant;
    final updated = active.copyWith(
      totalRemainingSeconds: max(0, active.totalRemainingSeconds - 1),
      totalUsedSeconds: active.totalUsedSeconds + 1,
      overtimeTotalSeconds: active.overtimeTotalSeconds + 1,
    );
    _snapshot = _snapshot.copyWith(
      participants: _replaceParticipant(updated),
      currentTurnOvertimeSeconds: _snapshot.currentTurnOvertimeSeconds + 1,
    );

    _emitTotalWarning(events);
    if (updated.totalRemainingSeconds == 0) {
      _enterNeedsExtension(updated.id, events);
      return;
    }

    _handlePenalty(events);
  }

  void _handleTurnLimitEnded(List<TimerEvent> events) {
    final overtime = _config.overtimeConfig;
    if (overtime.enabled && overtime.behavior == TurnLimitBehavior.overtime) {
      _snapshot = _snapshot.copyWith(
        phase: TimerPhase.runningOvertime,
        currentTurnOvertimeSeconds: 0,
      );
      events.add(
        OvertimeStartedEvent(participantId: _snapshot.activeParticipantId),
      );
      return;
    }

    if (overtime.behavior == TurnLimitBehavior.autoSwitch) {
      events.addAll(passTurn());
      return;
    }

    _resumePhase = null;
    _snapshot = _snapshot.copyWith(phase: TimerPhase.paused);
  }

  void _handlePenalty(List<TimerEvent> events) {
    final penalty = _config.penaltyConfig;
    if (!penalty.enabled) {
      return;
    }

    final overtimeSeconds = _snapshot.currentTurnOvertimeSeconds;
    switch (penalty.repeatMode) {
      case PenaltyRepeatMode.oncePerTurn:
        if (_snapshot.hasPenaltyInCurrentTurn ||
            overtimeSeconds < penalty.thresholdSeconds) {
          return;
        }
        _addPenalty(events, overtimeSeconds);
        _snapshot = _snapshot.copyWith(hasPenaltyInCurrentTurn: true);
        _lastPenaltyIndexInCurrentTurn = 1;
      case PenaltyRepeatMode.everyThreshold:
        final penaltyIndex = overtimeSeconds ~/ penalty.thresholdSeconds;
        if (penaltyIndex <= _lastPenaltyIndexInCurrentTurn) {
          return;
        }
        _addPenalty(events, overtimeSeconds);
        _lastPenaltyIndexInCurrentTurn = penaltyIndex;
    }
  }

  void _addPenalty(List<TimerEvent> events, int overtimeSeconds) {
    final active = _activeParticipant;
    final updated = active.copyWith(penaltyCount: active.penaltyCount + 1);
    _snapshot = _snapshot.copyWith(participants: _replaceParticipant(updated));
    events.add(
      PenaltyReachedEvent(
        participantId: updated.id,
        overtimeSeconds: overtimeSeconds,
        penaltyCount: updated.penaltyCount,
      ),
    );
  }

  void _emitWarnings(List<TimerEvent> events) {
    _emitTurnWarning(events);
    _emitTotalWarning(events);
  }

  void _emitTurnWarning(List<TimerEvent> events) {
    final alert = _config.alertConfig;
    if (!alert.turnWarningEnabled ||
        _snapshot.currentTurnRemainingSeconds != alert.warningBeforeSeconds) {
      return;
    }

    final key = 'turn-warning:$_turnId:${_snapshot.activeParticipantId}';
    if (_markFired(key)) {
      events.add(
        TurnWarningEvent(
          participantId: _snapshot.activeParticipantId,
          remainingSeconds: _snapshot.currentTurnRemainingSeconds,
        ),
      );
    }
  }

  void _emitTotalWarning(List<TimerEvent> events) {
    final alert = _config.alertConfig;
    final active = _activeParticipant;
    if (!alert.totalWarningEnabled ||
        active.totalRemainingSeconds != alert.warningBeforeSeconds) {
      return;
    }

    final key = 'total-warning:${active.id}:${active.totalRemainingSeconds}';
    if (_markFired(key)) {
      events.add(
        TotalWarningEvent(
          participantId: active.id,
          remainingSeconds: active.totalRemainingSeconds,
        ),
      );
    }
  }

  bool _markFired(String key) {
    if (_snapshot.firedAlertKeys.contains(key)) {
      return false;
    }

    _snapshot = _snapshot.copyWith(
      firedAlertKeys: {..._snapshot.firedAlertKeys, key},
    );
    return true;
  }

  void _enterNeedsExtension(String participantId, List<TimerEvent>? events) {
    _resumePhase = null;
    _snapshot = _snapshot.copyWith(
      phase: TimerPhase.needsExtension,
      activeParticipantId: participantId,
    );
    events?.add(TotalTimeEndedEvent(participantId: participantId));
  }

  Participant get _activeParticipant {
    return _participantById(_snapshot.activeParticipantId);
  }

  Participant _otherParticipant(String participantId) {
    return _snapshot.participants.singleWhere(
      (participant) => participant.id != participantId,
    );
  }

  Participant _participantById(String participantId) {
    return _snapshot.participants.singleWhere(
      (participant) => participant.id == participantId,
    );
  }

  List<Participant> _replaceParticipant(Participant participant) {
    return List.unmodifiable(
      _snapshot.participants.map((item) {
        return item.id == participant.id ? participant : item;
      }),
    );
  }

  static void _validateConfig(SessionConfig config) {
    final participantIds = {config.participantA.id, config.participantB.id};
    if (participantIds.length != 2) {
      throw ArgumentError('participant ids must be unique');
    }
    if (!participantIds.contains(config.firstSpeakerId)) {
      throw ArgumentError('firstSpeakerId must match a participant id');
    }
  }
}
