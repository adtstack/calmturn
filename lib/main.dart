import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'features/history/session_record.dart';
import 'features/history/session_record_store.dart';
import 'features/history/wrap_up_page.dart';
import 'features/settings/session_setup_page.dart';
import 'features/timer/domain/timer_engine.dart';
import 'features/timer/domain/timer_models.dart';
import 'features/timer/timer_feedback.dart';

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
      home: _CalmTurnRoot(),
    );
  }
}

final class _CalmTurnRoot extends StatefulWidget {
  const _CalmTurnRoot();

  @override
  State<_CalmTurnRoot> createState() => _CalmTurnRootState();
}

final class _CalmTurnRootState extends State<_CalmTurnRoot> {
  SessionConfig? _sessionConfig;

  @override
  Widget build(BuildContext context) {
    final config = _sessionConfig;
    if (config == null) {
      return SessionSetupPage(
        onSessionAccepted: (acceptedConfig) {
          setState(() {
            _sessionConfig = acceptedConfig;
          });
        },
      );
    }

    return TimerHomePage(config: config);
  }
}

final class TimerHomePage extends StatefulWidget {
  final SessionConfig config;
  final TimerFeedbackService feedbackService;
  final SessionRecordStore? recordStore;

  const TimerHomePage({
    super.key,
    required this.config,
    this.feedbackService = const TimerFeedbackService(),
    this.recordStore,
  });

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

final class _TimerHomePageState extends State<TimerHomePage> {
  late TimerEngine _engine;
  late SessionRecordStore _recordStore;
  late DateTime _startedAt;
  Timer? _ticker;
  List<TimerEvent> _lastEvents = const [];
  List<TimerFeedbackCue> _feedbackCues = const [];
  SessionRecord? _wrapUpRecord;
  int _breakCount = 0;
  int _totalBreakSeconds = 0;
  DateTime? _breakStartedAt;

  TimerSnapshot get _snapshot => _engine.snapshot();

  bool get _isTicking => _ticker?.isActive ?? false;

  bool get _isRunningPhase {
    return _snapshot.phase == TimerPhase.runningNormal ||
        _snapshot.phase == TimerPhase.runningOvertime;
  }

  @override
  void initState() {
    super.initState();
    _recordStore = widget.recordStore ?? JsonSessionRecordStore.local();
    _beginSession();
    _startTickerAfterBuild();
  }

  @override
  void didUpdateWidget(covariant TimerHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config == widget.config) {
      if (oldWidget.recordStore != widget.recordStore &&
          widget.recordStore != null) {
        _recordStore = widget.recordStore!;
      }
      return;
    }

    _stopTicker();
    _beginSession();
    _startTickerAfterBuild();
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

  void _startTickerAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startTicker();
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _beginSession() {
    _engine = TimerEngine.start(widget.config);
    _startedAt = DateTime.now();
    _lastEvents = const [];
    _feedbackCues = const [];
    _wrapUpRecord = null;
    _breakCount = 0;
    _totalBreakSeconds = 0;
    _breakStartedAt = null;
  }

  void _commit(List<TimerEvent> events) {
    final cues = events.isEmpty
        ? _feedbackCues
        : widget.feedbackService.cuesFor(events, widget.config);
    if (events.isNotEmpty) {
      unawaited(
        widget.feedbackService.dispatch(cues, widget.config.alertConfig),
      );
    }

    final shouldStop = !_isRunningPhase;
    setState(() {
      if (events.isNotEmpty) {
        _lastEvents = events;
        _feedbackCues = cues
            .where((cue) => cue.showOnScreen)
            .toList(growable: false);
      }
    });
    if (shouldStop) {
      _stopTicker();
    }
  }

  void _takeBreakOrResume() {
    if (_snapshot.phase == TimerPhase.paused) {
      if (!_engine.canResume) {
        return;
      }
      _finishActiveBreak(DateTime.now());
      _commit(_engine.resume());
      _startTicker();
      return;
    }

    final events = _engine.pause();
    if (events.isNotEmpty) {
      _breakCount += 1;
      _breakStartedAt = DateTime.now();
    }
    _commit(events);
    _stopTicker();
  }

  void _passTurn() {
    _commit(_engine.passTurn());
    if (_isRunningPhase) {
      _startTicker();
    }
  }

  void _addMinute() {
    _commit(_engine.addTime(_snapshot.activeParticipantId, 60));
    if (_isRunningPhase) {
      _startTicker();
    }
  }

  void _finish() {
    final endedAt = DateTime.now();
    final endReason = _snapshot.phase == TimerPhase.needsExtension
        ? SessionEndReason.timeEnded
        : SessionEndReason.endedByUser;
    _finishActiveBreak(endedAt);
    final events = _engine.finish();
    final record = SessionRecord.fromTimerSnapshot(
      id: newSessionRecordId(endedAt),
      config: widget.config,
      snapshot: _engine.snapshot(),
      startedAt: _startedAt,
      endedAt: endedAt,
      endReason: endReason,
      breakCount: _breakCount,
      totalBreakSeconds: _totalBreakSeconds,
    );
    _stopTicker();
    setState(() {
      _lastEvents = events;
      _feedbackCues = const [];
      _wrapUpRecord = record;
    });
  }

  void _reset() {
    _stopTicker();
    setState(() {
      _beginSession();
    });
    _startTicker();
  }

  void _finishActiveBreak(DateTime endedAt) {
    final startedAt = _breakStartedAt;
    if (startedAt == null) {
      return;
    }
    _totalBreakSeconds += endedAt.difference(startedAt).inSeconds;
    _breakStartedAt = null;
  }

  @override
  Widget build(BuildContext context) {
    final wrapUpRecord = _wrapUpRecord;
    if (wrapUpRecord != null) {
      return WrapUpPage(
        draftRecord: wrapUpRecord,
        recordStore: _recordStore,
        onStartAnotherSession: _reset,
      );
    }

    final snapshot = _snapshot;
    final activeParticipant = _participant(snapshot.activeParticipantId);
    final showOvertime = widget.config.overtimeConfig.showOvertime;
    final canResume = _engine.canResume;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('CalmTurn')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            _LiveTimerHero(
              snapshot: snapshot,
              activeParticipant: activeParticipant,
              feedbackCues: _feedbackCues,
              showOvertime: showOvertime,
              canResume: canResume,
            ),
            const SizedBox(height: 18),
            _Controls(
              phase: snapshot.phase,
              canResume: canResume,
              canPass:
                  snapshot.phase != TimerPhase.finished &&
                  snapshot.phase != TimerPhase.needsExtension,
              onBreakOrResume: _takeBreakOrResume,
              onPassTurn: _passTurn,
              onAddMinute: _addMinute,
              onFinish: _finish,
              onRestart: _reset,
            ),
            const SizedBox(height: 18),
            ...snapshot.participants.map((participant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParticipantPanel(
                  participant: participant,
                  isActive: participant.id == snapshot.activeParticipantId,
                  showOvertime: showOvertime,
                ),
              );
            }),
            const SizedBox(height: 18),
            _EventLog(events: _lastEvents, showOvertime: showOvertime),
          ],
        ),
      ),
    );
  }

  Participant _participant(String id) {
    return _snapshot.participants.singleWhere((item) => item.id == id);
  }
}

final class _LiveTimerHero extends StatelessWidget {
  final TimerSnapshot snapshot;
  final Participant activeParticipant;
  final List<TimerFeedbackCue> feedbackCues;
  final bool showOvertime;
  final bool canResume;

  const _LiveTimerHero({
    required this.snapshot,
    required this.activeParticipant,
    required this.feedbackCues,
    required this.showOvertime,
    required this.canResume,
  });

  @override
  Widget build(BuildContext context) {
    final isOvertime = snapshot.phase == TimerPhase.runningOvertime;
    final isAutoPaused = snapshot.phase == TimerPhase.paused && !canResume;
    final needsTurnLimitTone = isOvertime || isAutoPaused;
    final primaryTime = isOvertime
        ? showOvertime
              ? '+${formatSeconds(snapshot.currentTurnOvertimeSeconds)}'
              : 'Time is up'
        : formatSeconds(snapshot.currentTurnRemainingSeconds);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: needsTurnLimitTone
              ? const Color(0xFFC98B2B)
              : const Color(0xFF2D6A64),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Now speaking',
            style: TextStyle(
              color: Color(0xFF2D6A64),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _headline(
              snapshot.phase,
              activeParticipant.name,
              canResume: canResume,
            ),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              primaryTime,
              style: TextStyle(
                color: needsTurnLimitTone
                    ? const Color(0xFF8A5A13)
                    : const Color(0xFF1C2523),
                fontSize: isOvertime && !showOvertime ? 38 : 58,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Turn remaining',
                  value: formatSeconds(snapshot.currentTurnRemainingSeconds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: 'Total remaining',
                  value: formatSeconds(activeParticipant.totalRemainingSeconds),
                ),
              ),
            ],
          ),
          if (showOvertime &&
              (snapshot.phase == TimerPhase.runningOvertime ||
                  snapshot.currentTurnOvertimeSeconds > 0)) ...[
            const SizedBox(height: 12),
            _NoticeLine(
              'Overtime +${formatSeconds(snapshot.currentTurnOvertimeSeconds)}',
            ),
          ],
          if (feedbackCues.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FeedbackBanner(cues: feedbackCues),
          ],
        ],
      ),
    );
  }
}

final class _ParticipantPanel extends StatelessWidget {
  final Participant participant;
  final bool isActive;
  final bool showOvertime;

  const _ParticipantPanel({
    required this.participant,
    required this.isActive,
    required this.showOvertime,
  });

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
          if (isActive)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _NoticeLine('Active speaker'),
            ),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Total remaining',
                  value: formatSeconds(participant.totalRemainingSeconds),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Used',
                  value: formatSeconds(participant.totalUsedSeconds),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Marks',
                  value: participant.penaltyCount.toString(),
                ),
              ),
            ],
          ),
          if (showOvertime) ...[
            const SizedBox(height: 12),
            _Metric(
              label: 'Overtime total',
              value: formatSeconds(participant.overtimeTotalSeconds),
            ),
          ],
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
  final TimerPhase phase;
  final bool canResume;
  final bool canPass;
  final VoidCallback onBreakOrResume;
  final VoidCallback onPassTurn;
  final VoidCallback onAddMinute;
  final VoidCallback onFinish;
  final VoidCallback onRestart;

  const _Controls({
    required this.phase,
    required this.canResume,
    required this.canPass,
    required this.onBreakOrResume,
    required this.onPassTurn,
    required this.onAddMinute,
    required this.onFinish,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final canBreak =
        phase == TimerPhase.runningNormal ||
        phase == TimerPhase.runningOvertime ||
        (phase == TimerPhase.paused && canResume);
    final isPaused = phase == TimerPhase.paused;
    final isAutoPaused = isPaused && !canResume;
    final isFinished = phase == TimerPhase.finished;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton.filled(
          padding: const EdgeInsets.symmetric(vertical: 18),
          onPressed: canPass ? onPassTurn : null,
          child: const Text('Pass turn'),
        ),
        if (isAutoPaused) ...[
          const SizedBox(height: 8),
          const _NoticeLine('Pass turn to continue.'),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                color: const Color(0xFF1C2523),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: canBreak ? onBreakOrResume : null,
                child: Text(
                  isPaused
                      ? (canResume ? 'Resume' : 'Turn ended')
                      : 'Take break',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoButton(
                color: const Color(0xFF775A2C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: isFinished ? null : onFinish,
                child: const Text('End session'),
              ),
            ),
          ],
        ),
        if (phase == TimerPhase.needsExtension) ...[
          const SizedBox(height: 10),
          CupertinoButton(
            color: const Color(0xFF2D6A64),
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: onAddMinute,
            child: const Text('Add 1 minute'),
          ),
        ],
        if (isFinished) ...[
          const SizedBox(height: 10),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 14),
            onPressed: onRestart,
            child: const Text('Restart session'),
          ),
        ],
      ],
    );
  }
}

final class _FeedbackBanner extends StatelessWidget {
  final List<TimerFeedbackCue> cues;

  const _FeedbackBanner({required this.cues});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0CC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0AE4C)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          cues.map((cue) => cue.message).join('\n'),
          style: const TextStyle(
            color: Color(0xFF5C4212),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

final class _EventLog extends StatelessWidget {
  final List<TimerEvent> events;
  final bool showOvertime;

  const _EventLog({required this.events, required this.showOvertime});

  @override
  Widget build(BuildContext context) {
    final label = events.isEmpty
        ? 'No events yet'
        : events.map((event) => _eventLabel(event, showOvertime)).join('\n');
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

final class _NoticeLine extends StatelessWidget {
  final String text;

  const _NoticeLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF5F6964),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

String _headline(
  TimerPhase phase,
  String activeName, {
  required bool canResume,
}) {
  return switch (phase) {
    TimerPhase.paused => canResume ? 'Taking a break' : 'Turn limit reached',
    TimerPhase.needsExtension => '$activeName needs more time',
    TimerPhase.finished => 'Session finished',
    _ => '$activeName is speaking',
  };
}

String _eventLabel(TimerEvent event, bool showOvertime) {
  return switch (event) {
    TurnWarningEvent(:final participantId, :final remainingSeconds) =>
      '$participantId turn warning: ${formatSeconds(remainingSeconds)}',
    TotalWarningEvent(:final participantId, :final remainingSeconds) =>
      '$participantId total warning: ${formatSeconds(remainingSeconds)}',
    OvertimeStartedEvent(:final participantId) =>
      showOvertime
          ? '$participantId entered overtime'
          : '$participantId reached turn limit',
    PenaltyReachedEvent(
      :final participantId,
      :final overtimeSeconds,
      :final penaltyCount,
    ) =>
      showOvertime
          ? '$participantId penalty $penaltyCount at ${formatSeconds(overtimeSeconds)}'
          : '$participantId mark $penaltyCount recorded',
    TurnPassedEvent(:final fromParticipantId, :final toParticipantId) =>
      '$fromParticipantId passed to $toParticipantId',
    TotalTimeEndedEvent(:final participantId) =>
      '$participantId needs more time',
    SessionPausedEvent(:final participantId) => '$participantId paused',
    SessionFinishedEvent() => 'Session finished',
    TimeAddedEvent(:final participantId, :final addedSeconds) =>
      '$participantId added ${formatSeconds(addedSeconds)}',
  };
}
