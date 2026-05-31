import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'features/history/session_record.dart';
import 'features/history/session_record_store.dart';
import 'features/history/wrap_up_page.dart';
import 'features/settings/app_settings.dart';
import 'features/settings/app_settings_platform_storage_stub.dart'
    if (dart.library.io) 'features/settings/app_settings_platform_storage_io.dart'
    as platform_storage;
import 'features/settings/session_setup_page.dart';
import 'features/settings/settings_screen.dart';
import 'features/timer/domain/timer_engine.dart';
import 'features/timer/domain/timer_models.dart';
import 'features/timer/timer_feedback.dart';

void main() {
  platform_storage.configurePlatformAppSettingsStorage();
  runApp(const CalmTurnApp());
}

final class CalmTurnApp extends StatelessWidget {
  final AppSettingsStore? settingsStore;
  final SessionRecordStore? recordStore;

  const CalmTurnApp({super.key, this.settingsStore, this.recordStore});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: '말차례 CalmTurn',
      theme: const CupertinoThemeData(
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
      home: _CalmTurnRoot(
        settingsStore: settingsStore,
        recordStore: recordStore,
      ),
    );
  }
}

final class _CalmTurnRoot extends StatefulWidget {
  final AppSettingsStore? settingsStore;
  final SessionRecordStore? recordStore;

  const _CalmTurnRoot({this.settingsStore, this.recordStore});

  @override
  State<_CalmTurnRoot> createState() => _CalmTurnRootState();
}

final class _CalmTurnRootState extends State<_CalmTurnRoot> {
  late final AppSettingsStore _settingsStore;
  late final SessionRecordStore _recordStore;
  SessionConfig? _sessionConfig;
  AppSettingsDraft _appSettings = AppSettingsDraft.defaults();
  bool _isEditingAppSettings = false;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _settingsStore = widget.settingsStore ?? JsonAppSettingsStore.local();
    _recordStore = widget.recordStore ?? JsonSessionRecordStore.local();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    SessionConfig? config;
    try {
      config = await _settingsStore.loadSessionConfig();
    } catch (_) {
      config = null;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionConfig = config;
      _isLoadingSettings = false;
    });
  }

  Future<void> _acceptSession(SessionConfig acceptedConfig) async {
    try {
      await _settingsStore.saveSessionConfig(acceptedConfig);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionConfig = acceptedConfig;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings) {
      return const CupertinoPageScaffold(
        child: Center(child: Text('설정을 불러오는 중')),
      );
    }

    if (_isEditingAppSettings) {
      return SettingsScreen(
        settings: _appSettings,
        recordStore: _recordStore,
        onSettingsChanged: (settings) {
          setState(() {
            _appSettings = settings;
          });
        },
        onBack: () {
          setState(() {
            _isEditingAppSettings = false;
          });
        },
      );
    }

    final config = _sessionConfig;
    if (config == null) {
      return SessionSetupPage(
        initialDraft: _appSettings.sessionDefaults,
        onOpenAppSettings: () {
          setState(() {
            _isEditingAppSettings = true;
          });
        },
        onSessionAccepted: (acceptedConfig) {
          unawaited(_acceptSession(acceptedConfig));
        },
      );
    }

    return TimerHomePage(
      config: config,
      recordStore: _recordStore,
      autoSaveRecords: _appSettings.autoSaveRecords,
    );
  }
}

final class TimerHomePage extends StatefulWidget {
  final SessionConfig config;
  final TimerFeedbackService feedbackService;
  final SessionRecordStore? recordStore;
  final bool autoSaveRecords;

  const TimerHomePage({
    super.key,
    required this.config,
    this.feedbackService = const TimerFeedbackService(),
    this.recordStore,
    this.autoSaveRecords = false,
  });

  @override
  State<TimerHomePage> createState() => _TimerHomePageState();
}

final class _TimerHomePageState extends State<TimerHomePage> {
  late TimerEngine _engine;
  late SessionRecordStore _recordStore;
  late DateTime _startedAt;
  Timer? _ticker;
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
    _engine.finish();
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
    if (widget.autoSaveRecords) {
      unawaited(_recordStore.save(record));
    }
    _stopTicker();
    setState(() {
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
    final participantA = _participant(widget.config.participantA.id);
    final participantB = _participant(widget.config.participantB.id);
    final showOvertime = widget.config.overtimeConfig.showOvertime;
    final canResume = _engine.canResume;
    final canPass =
        snapshot.phase != TimerPhase.finished &&
        snapshot.phase != TimerPhase.needsExtension;

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _FaceTimerZone(
                    key: const ValueKey('face-timer-top-zone'),
                    rotationKey: const ValueKey('face-timer-top-rotation'),
                    participant: participantB,
                    snapshot: snapshot,
                    feedbackCues: _feedbackCues,
                    showOvertime: showOvertime,
                    canResume: canResume,
                    isRotated: true,
                    onPassTurn: canPass ? _passTurn : null,
                  ),
                ),
                Expanded(
                  child: _FaceTimerZone(
                    key: const ValueKey('face-timer-bottom-zone'),
                    participant: participantA,
                    snapshot: snapshot,
                    feedbackCues: _feedbackCues,
                    showOvertime: showOvertime,
                    canResume: canResume,
                    isRotated: false,
                    onPassTurn: canPass ? _passTurn : null,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD4CEC2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _Controls(
                        phase: snapshot.phase,
                        canResume: canResume,
                        canPass: canPass,
                        onBreakOrResume: _takeBreakOrResume,
                        onPassTurn: _passTurn,
                        onAddMinute: _addMinute,
                        onFinish: _finish,
                        onRestart: _reset,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Participant _participant(String id) {
    return _snapshot.participants.singleWhere((item) => item.id == id);
  }
}

final class _FaceTimerZone extends StatelessWidget {
  final Key? rotationKey;
  final Participant participant;
  final TimerSnapshot snapshot;
  final List<TimerFeedbackCue> feedbackCues;
  final bool showOvertime;
  final bool canResume;
  final bool isRotated;
  final VoidCallback? onPassTurn;

  const _FaceTimerZone({
    super.key,
    this.rotationKey,
    required this.participant,
    required this.snapshot,
    required this.feedbackCues,
    required this.showOvertime,
    required this.canResume,
    required this.isRotated,
    required this.onPassTurn,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = participant.id == snapshot.activeParticipantId;
    final isOvertime = snapshot.phase == TimerPhase.runningOvertime;
    final isAutoPaused = snapshot.phase == TimerPhase.paused && !canResume;
    final needsTurnLimitTone = isActive && (isOvertime || isAutoPaused);
    final turnTime = isOvertime
        ? showOvertime
              ? '+${formatSeconds(snapshot.currentTurnOvertimeSeconds)}'
              : '차례 시간이 끝났어요'
        : formatSeconds(snapshot.currentTurnRemainingSeconds);
    final primaryTime = isActive
        ? turnTime
        : formatSeconds(participant.totalRemainingSeconds);
    final content = LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 22.0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            14,
            horizontalPadding,
            14,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: math.max(
                  0,
                  constraints.maxWidth - horizontalPadding * 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isActive ? '지금 말하는 중' : '듣는 시간',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF2D6A64)
                            : const Color(0xFF646B66),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive
                          ? _headline(
                              snapshot.phase,
                              participant.name,
                              canResume: canResume,
                            )
                          : '${participant.name}님은 듣는 중',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      primaryTime,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: needsTurnLimitTone
                            ? const Color(0xFF8A5A13)
                            : const Color(0xFF1C2523),
                        fontSize: isActive && isOvertime && !showOvertime
                            ? 38
                            : 62,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Metric(
                            label: '전체 남은 시간',
                            value: formatSeconds(
                              participant.totalRemainingSeconds,
                            ),
                            align: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Metric(
                            label: isActive ? '이번 차례' : '대기 중',
                            value: isActive
                                ? formatSeconds(
                                    snapshot.currentTurnRemainingSeconds,
                                  )
                                : '듣는 중',
                            align: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    if (isActive &&
                        showOvertime &&
                        (snapshot.phase == TimerPhase.runningOvertime ||
                            snapshot.currentTurnOvertimeSeconds > 0)) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: _NoticeLine(
                          '오버타임 +${formatSeconds(snapshot.currentTurnOvertimeSeconds)}',
                        ),
                      ),
                    ],
                    if (isActive && feedbackCues.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _FeedbackBanner(cues: feedbackCues),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    final rotatedContent = isRotated
        ? Transform.rotate(key: rotationKey, angle: math.pi, child: content)
        : content;

    return Semantics(
      button: onPassTurn != null,
      label: '${participant.name} 타이머 영역',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPassTurn,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _zoneColor(isActive, needsTurnLimitTone),
            border: Border(
              bottom: isRotated
                  ? const BorderSide(color: Color(0xFFCEC8BA), width: 1)
                  : BorderSide.none,
              top: isRotated
                  ? BorderSide.none
                  : const BorderSide(color: Color(0xFFCEC8BA), width: 1),
            ),
          ),
          child: rotatedContent,
        ),
      ),
    );
  }
}

Color _zoneColor(bool isActive, bool needsTurnLimitTone) {
  if (needsTurnLimitTone) {
    return const Color(0xFFFFF0CC);
  }
  return isActive ? const Color(0xFFE7F1EC) : const Color(0xFFF8F6F0);
}

final class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final TextAlign align;

  const _Metric({
    required this.label,
    required this.value,
    this.align = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: align,
          style: const TextStyle(
            color: Color(0xFF6D746F),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: align,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: canPass ? onPassTurn : null,
                child: const _ControlLabel('차례 넘기기'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                color: const Color(0xFF1C2523),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: canBreak ? onBreakOrResume : null,
                child: Text(
                  isPaused ? (canResume ? '이어서 하기' : '차례 끝') : '잠깐 쉬기',
                  maxLines: 1,
                  style: const TextStyle(color: CupertinoColors.white),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                color: const Color(0xFF775A2C),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: isFinished ? null : onFinish,
                child: const _ControlLabel('오늘은 여기까지'),
              ),
            ),
          ],
        ),
        if (isAutoPaused) ...[
          const SizedBox(height: 8),
          const _NoticeLine('차례를 넘기면 이어집니다.'),
        ],
        if (phase == TimerPhase.needsExtension) ...[
          const SizedBox(height: 8),
          CupertinoButton(
            color: const Color(0xFF2D6A64),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onAddMinute,
            child: const _ControlLabel('1분 더하기'),
          ),
        ],
        if (isFinished) ...[
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onRestart,
            child: const Text('새 대화 시작'),
          ),
        ],
      ],
    );
  }
}

final class _ControlLabel extends StatelessWidget {
  final String text;

  const _ControlLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
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
    TimerPhase.paused => canResume ? '잠깐 쉬는 중' : '차례가 끝났어요',
    TimerPhase.needsExtension => '$activeName님의 전체 시간이 끝났어요',
    TimerPhase.finished => '대화가 끝났어요',
    _ => '$activeName님 차례',
  };
}
