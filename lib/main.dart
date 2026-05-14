import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'features/timer/domain/timer_engine.dart';
import 'features/timer/domain/timer_models.dart';

void main() {
  runApp(const CalmTurnApp());
}

final class CalmTurnApp extends StatelessWidget {
  const CalmTurnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'CalmTurn',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF2D6A64),
        scaffoldBackgroundColor: Color(0xFFF6F4EF),
        textTheme: CupertinoTextThemeData(
          primaryColor: Color(0xFF1C2523),
          textStyle: TextStyle(
            color: Color(0xFF1C2523),
            fontSize: 16,
            height: 1.3,
          ),
        ),
      ),
      home: TimerHomePage(),
    );
  }
}

final class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

final class _TimerHomePageState extends State<TimerHomePage> {
  late TimerEngine _engine;
  Timer? _ticker;
  List<TimerEvent> _lastEvents = const [];

  TimerSnapshot get _snapshot => _engine.snapshot();

  bool get _isTicking => _ticker?.isActive ?? false;

  bool get _isRunningPhase {
    return _snapshot.phase == TimerPhase.runningNormal ||
        _snapshot.phase == TimerPhase.runningOvertime;
  }

  @override
  void initState() {
    super.initState();
    _engine = TimerEngine.start(_defaultConfig());
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _startTicker() {
    if (_isTicking || !_isRunningPhase) {
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _commit(_engine.tick(const Duration(seconds: 1)));
    });
    setState(() {});
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _commit(List<TimerEvent> events) {
    final shouldStop = !_isRunningPhase;
    setState(() {
      if (events.isNotEmpty) {
        _lastEvents = events;
      }
    });
    if (shouldStop) {
      _stopTicker();
    }
  }

  void _toggleTimer() {
    if (_isTicking) {
      _commit(_engine.pause());
      _stopTicker();
      return;
    }

    if (_snapshot.phase == TimerPhase.paused) {
      _commit(_engine.resume());
    }
    _startTicker();
  }

  void _passTurn() {
    _commit(_engine.passTurn());
  }

  void _addMinute() {
    _commit(_engine.addTime(_snapshot.activeParticipantId, 60));
  }

  void _reset() {
    _stopTicker();
    setState(() {
      _engine = TimerEngine.start(_defaultConfig());
      _lastEvents = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final activeParticipant = _participant(snapshot.activeParticipantId);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('CalmTurn')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            _SessionHeader(
              phase: _phaseLabel(snapshot.phase),
              activeName: activeParticipant.name,
              turnRemaining: _formatSeconds(
                snapshot.currentTurnRemainingSeconds,
              ),
              overtime: _formatSeconds(snapshot.currentTurnOvertimeSeconds),
            ),
            const SizedBox(height: 18),
            ...snapshot.participants.map((participant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParticipantPanel(
                  participant: participant,
                  isActive: participant.id == snapshot.activeParticipantId,
                ),
              );
            }),
            const SizedBox(height: 8),
            _Controls(
              primaryLabel: _primaryLabel(snapshot.phase),
              canStart: _isRunningPhase || snapshot.phase == TimerPhase.paused,
              canPass:
                  snapshot.phase != TimerPhase.finished &&
                  snapshot.phase != TimerPhase.needsExtension,
              onPrimary: _toggleTimer,
              onPassTurn: _passTurn,
              onAddMinute: _addMinute,
              onReset: _reset,
            ),
            const SizedBox(height: 18),
            _EventLog(events: _lastEvents),
          ],
        ),
      ),
    );
  }

  Participant _participant(String id) {
    return _snapshot.participants.singleWhere((item) => item.id == id);
  }

  String _primaryLabel(TimerPhase phase) {
    if (_isTicking) {
      return 'Pause';
    }
    if (phase == TimerPhase.paused) {
      return 'Resume';
    }
    return 'Start';
  }
}

final class _SessionHeader extends StatelessWidget {
  final String phase;
  final String activeName;
  final String turnRemaining;
  final String overtime;

  const _SessionHeader({
    required this.phase,
    required this.activeName,
    required this.turnRemaining,
    required this.overtime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D4C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            phase,
            style: const TextStyle(
              color: Color(0xFF2D6A64),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activeName,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Turn', value: turnRemaining),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(label: 'Overtime', value: overtime),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ParticipantPanel extends StatelessWidget {
  final Participant participant;
  final bool isActive;

  const _ParticipantPanel({required this.participant, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE7F1EC) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF2D6A64) : const Color(0xFFD9D4C8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participant.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Remaining',
                  value: _formatSeconds(participant.totalRemainingSeconds),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Used',
                  value: _formatSeconds(participant.totalUsedSeconds),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Penalty',
                  value: participant.penaltyCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6D746F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

final class _Controls extends StatelessWidget {
  final String primaryLabel;
  final bool canStart;
  final bool canPass;
  final VoidCallback onPrimary;
  final VoidCallback onPassTurn;
  final VoidCallback onAddMinute;
  final VoidCallback onReset;

  const _Controls({
    required this.primaryLabel,
    required this.canStart,
    required this.canPass,
    required this.onPrimary,
    required this.onPassTurn,
    required this.onAddMinute,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          onPressed: canStart ? onPrimary : null,
          child: Text(primaryLabel),
        ),
        CupertinoButton(
          color: const Color(0xFF1C2523),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          onPressed: canPass ? onPassTurn : null,
          child: const Text('Pass Turn'),
        ),
        CupertinoButton(
          color: const Color(0xFF775A2C),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          onPressed: onAddMinute,
          child: const Text('+1 min'),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          onPressed: onReset,
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

final class _EventLog extends StatelessWidget {
  final List<TimerEvent> events;

  const _EventLog({required this.events});

  @override
  Widget build(BuildContext context) {
    final label = events.isEmpty
        ? 'No events yet'
        : events.map(_eventLabel).join('\n');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE8DC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label),
    );
  }
}

SessionConfig _defaultConfig() {
  return const SessionConfig(
    participantA: ParticipantConfig(
      id: 'a',
      name: 'Speaker A',
      totalAllocatedSeconds: 300,
    ),
    participantB: ParticipantConfig(
      id: 'b',
      name: 'Speaker B',
      totalAllocatedSeconds: 300,
    ),
    turnLimitSeconds: 60,
    firstSpeakerId: 'a',
    overtimeConfig: OvertimeConfig(),
    penaltyConfig: PenaltyConfig(),
    alertConfig: AlertConfig(warningBeforeSeconds: 10),
  );
}

String _formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _phaseLabel(TimerPhase phase) {
  return switch (phase) {
    TimerPhase.draft => 'Draft',
    TimerPhase.waitingConsent => 'Waiting Consent',
    TimerPhase.runningNormal => 'Running',
    TimerPhase.runningOvertime => 'Overtime',
    TimerPhase.paused => 'Paused',
    TimerPhase.needsExtension => 'Needs Extension',
    TimerPhase.finished => 'Finished',
  };
}

String _eventLabel(TimerEvent event) {
  return switch (event) {
    TurnWarningEvent(:final participantId, :final remainingSeconds) =>
      '$participantId turn warning: ${_formatSeconds(remainingSeconds)}',
    TotalWarningEvent(:final participantId, :final remainingSeconds) =>
      '$participantId total warning: ${_formatSeconds(remainingSeconds)}',
    OvertimeStartedEvent(:final participantId) =>
      '$participantId entered overtime',
    PenaltyReachedEvent(
      :final participantId,
      :final overtimeSeconds,
      :final penaltyCount,
    ) =>
      '$participantId penalty $penaltyCount at ${_formatSeconds(overtimeSeconds)}',
    TurnPassedEvent(:final fromParticipantId, :final toParticipantId) =>
      '$fromParticipantId passed to $toParticipantId',
    TotalTimeEndedEvent(:final participantId) =>
      '$participantId needs more time',
    SessionPausedEvent(:final participantId) => '$participantId paused',
    SessionFinishedEvent() => 'Session finished',
    TimeAddedEvent(:final participantId, :final addedSeconds) =>
      '$participantId added ${_formatSeconds(addedSeconds)}',
  };
}
