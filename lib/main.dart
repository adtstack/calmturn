import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'features/history/session_record.dart';
import 'features/history/session_record_store.dart';
import 'features/history/history_screen.dart';
import 'features/history/wrap_up_page.dart';
import 'features/settings/app_settings.dart';
import 'features/settings/app_settings_platform_storage_stub.dart'
    if (dart.library.io) 'features/settings/app_settings_platform_storage_io.dart'
    as platform_storage;
import 'features/settings/session_setup_page.dart';
import 'features/settings/session_settings.dart';
import 'features/settings/settings_screen.dart';
import 'features/timer/domain/timer_engine.dart';
import 'features/timer/domain/timer_models.dart';
import 'features/timer/timer_display_controller.dart';
import 'features/timer/timer_feedback.dart';

const _clockBoundaryAnimationDuration = Duration(milliseconds: 700);

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
      title: '시계 (부부싸움 시리즈)',
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
    AppSettingsDraft settings;
    try {
      settings = await _settingsStore.loadSettings();
    } catch (_) {
      settings = AppSettingsDraft.defaults();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionConfig = null;
      _appSettings = settings;
      _isLoadingSettings = false;
    });
  }

  Future<void> _acceptSession(SessionConfig acceptedConfig) async {
    final acceptedSettings = _appSettings.copyWith(
      sessionDefaults: SessionSettingsDraft.fromSessionConfig(acceptedConfig),
    );
    try {
      await _settingsStore.saveSettings(acceptedSettings);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _appSettings = acceptedSettings;
      _sessionConfig = acceptedConfig;
    });
  }

  void _openHistory() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) {
          return HistoryScreen(recordStore: _recordStore);
        },
      ),
    );
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
          unawaited(_settingsStore.saveSettings(settings));
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
        onOpenHistory: _openHistory,
        onSessionAccepted: (acceptedConfig) {
          unawaited(_acceptSession(acceptedConfig));
        },
      );
    }

    return TimerHomePage(
      config: config,
      recordStore: _recordStore,
      autoSaveRecords: _appSettings.autoSaveRecords,
      onReturnToSetup: () {
        setState(() {
          _sessionConfig = null;
        });
      },
    );
  }
}

final class TimerHomePage extends StatefulWidget {
  final SessionConfig config;
  final TimerFeedbackService feedbackService;
  final TimerDisplayController timerDisplayController;
  final SessionRecordStore? recordStore;
  final bool autoSaveRecords;
  final VoidCallback? onReturnToSetup;

  const TimerHomePage({
    super.key,
    required this.config,
    this.feedbackService = const TimerFeedbackService(),
    this.timerDisplayController = const PlatformTimerDisplayController(),
    this.recordStore,
    this.autoSaveRecords = false,
    this.onReturnToSetup,
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
  bool _timerDisplayActive = false;

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
    _activateTimerDisplay();
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
    _restoreTimerDisplay();
    _beginSession();
    _activateTimerDisplay();
    _startTickerAfterBuild();
  }

  @override
  void dispose() {
    _stopTicker();
    _restoreTimerDisplay();
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

  void _activateTimerDisplay() {
    if (_timerDisplayActive) {
      return;
    }
    _timerDisplayActive = true;
    unawaited(widget.timerDisplayController.activate());
  }

  void _restoreTimerDisplay() {
    if (!_timerDisplayActive) {
      return;
    }
    _timerDisplayActive = false;
    unawaited(widget.timerDisplayController.restore());
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

  Future<void> _confirmFinish() async {
    final shouldFinish = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('종료할까요?'),
          content: const Text('지금 대화를 종료하고 마무리 화면으로 이동합니다.'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('종료'),
            ),
          ],
        );
      },
    );
    if (shouldFinish == true && mounted) {
      await _finish();
    }
  }

  Future<void> _finish() async {
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
      try {
        await _recordStore.save(record);
      } catch (_) {}
    }
    _stopTicker();
    _restoreTimerDisplay();
    if (!mounted) {
      return;
    }
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
    _activateTimerDisplay();
    _startTicker();
  }

  void _handleWrapUpComplete() {
    final onReturnToSetup = widget.onReturnToSetup;
    if (onReturnToSetup != null) {
      onReturnToSetup();
      return;
    }
    _reset();
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
        recordWasAutoSaved: widget.autoSaveRecords,
        onStartAnotherSession: _handleWrapUpComplete,
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
            _ClockZoneLayout(
              participantA: participantA,
              participantB: participantB,
              snapshot: snapshot,
              feedbackCues: _feedbackCues,
              turnLimitSeconds: widget.config.turnLimitSeconds,
              turnDangerFlashEnabled:
                  widget.config.alertConfig.turnDangerFlashEnabled,
              showOvertime: showOvertime,
              canResume: canResume,
              onPassTurn: canPass ? _passTurn : null,
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _ClockControls(
                phase: snapshot.phase,
                canResume: canResume,
                onPauseOrResume: _takeBreakOrResume,
                onFinish: _confirmFinish,
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

final class _ClockZoneLayout extends StatelessWidget {
  final Participant participantA;
  final Participant participantB;
  final TimerSnapshot snapshot;
  final List<TimerFeedbackCue> feedbackCues;
  final int turnLimitSeconds;
  final bool turnDangerFlashEnabled;
  final bool showOvertime;
  final bool canResume;
  final VoidCallback? onPassTurn;

  const _ClockZoneLayout({
    required this.participantA,
    required this.participantB,
    required this.snapshot,
    required this.feedbackCues,
    required this.turnLimitSeconds,
    required this.turnDangerFlashEnabled,
    required this.showOvertime,
    required this.canResume,
    required this.onPassTurn,
  });

  @override
  Widget build(BuildContext context) {
    final totalRemainingSeconds =
        participantA.totalRemainingSeconds + participantB.totalRemainingSeconds;
    if (totalRemainingSeconds <= 0) {
      return const SizedBox.shrink();
    }

    final leftTargetFraction =
        participantA.totalRemainingSeconds / totalRemainingSeconds;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        if (!totalWidth.isFinite || totalWidth <= 0) {
          return const SizedBox.shrink();
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: leftTargetFraction,
            end: leftTargetFraction,
          ),
          duration: _clockBoundaryAnimationDuration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedLeftFraction, child) {
            final leftFraction = animatedLeftFraction.clamp(0.0, 1.0);
            final leftWidth = totalWidth * leftFraction;
            final rightWidth = totalWidth - leftWidth;
            final showLeft = _shouldShowClockZone(participantA, leftWidth);
            final showRight = _shouldShowClockZone(participantB, rightWidth);

            return Stack(
              fit: StackFit.expand,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLeft)
                      SizedBox(
                        key: const ValueKey('clock-left-zone'),
                        width: leftWidth,
                        child: const _ClockZoneBackground(isDark: false),
                      ),
                    if (showRight)
                      SizedBox(
                        key: const ValueKey('clock-right-zone'),
                        width: rightWidth,
                        child: const _ClockZoneBackground(isDark: true),
                      ),
                  ],
                ),
                _TurnDangerFlash(
                  snapshot: snapshot,
                  turnLimitSeconds: turnLimitSeconds,
                  enabled: turnDangerFlashEnabled,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLeft)
                      Expanded(
                        child: _ClockReadout(
                          participant: participantA,
                          snapshot: snapshot,
                          feedbackCues: feedbackCues,
                          showOvertime: showOvertime,
                          canResume: canResume,
                          isDark: false,
                          onPassTurn: onPassTurn,
                        ),
                      ),
                    if (showRight)
                      Expanded(
                        child: _ClockReadout(
                          participant: participantB,
                          snapshot: snapshot,
                          feedbackCues: feedbackCues,
                          showOvertime: showOvertime,
                          canResume: canResume,
                          isDark: true,
                          onPassTurn: onPassTurn,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

bool _shouldShowClockZone(Participant participant, double width) {
  return participant.totalRemainingSeconds > 0 || width > 0.5;
}

final class _ClockZoneBackground extends StatelessWidget {
  final bool isDark;

  const _ClockZoneBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? const Color(0xFF171717)
        : const Color(0xFFF7F7F4);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: isDark
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFE1E1DC)),
        ),
      ),
    );
  }
}

final class _TurnDangerFlash extends StatelessWidget {
  final TimerSnapshot snapshot;
  final int turnLimitSeconds;
  final bool enabled;

  const _TurnDangerFlash({
    required this.snapshot,
    required this.turnLimitSeconds,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final level = _turnDangerFlashLevel(
      snapshot: snapshot,
      turnLimitSeconds: turnLimitSeconds,
      enabled: enabled,
    );
    if (level == 0) {
      return const SizedBox.shrink();
    }

    final pulseSeed = snapshot.phase == TimerPhase.runningOvertime
        ? snapshot.currentTurnOvertimeSeconds
        : snapshot.currentTurnRemainingSeconds;
    final pulseHigh = pulseSeed.isEven;
    final opacity = switch (level) {
      1 => pulseHigh ? 0.18 : 0.08,
      _ => pulseHigh ? 0.34 : 0.16,
    };

    return IgnorePointer(
      child: Opacity(
        key: const ValueKey('turn-danger-flash-overlay'),
        opacity: opacity,
        child: const ColoredBox(color: Color(0xFFEF3B2D)),
      ),
    );
  }
}

int _turnDangerFlashLevel({
  required TimerSnapshot snapshot,
  required int turnLimitSeconds,
  required bool enabled,
}) {
  if (!enabled || turnLimitSeconds <= 0) {
    return 0;
  }
  if (snapshot.phase == TimerPhase.runningOvertime) {
    return 2;
  }
  if (snapshot.phase != TimerPhase.runningNormal) {
    return 0;
  }

  final remainingSeconds = snapshot.currentTurnRemainingSeconds;
  if (remainingSeconds <= 0) {
    return 0;
  }

  final warningThresholdSeconds = (turnLimitSeconds * 0.2).ceil();
  final criticalThresholdSeconds = (turnLimitSeconds * 0.1).ceil();
  if (remainingSeconds <= criticalThresholdSeconds) {
    return 2;
  }
  if (remainingSeconds <= warningThresholdSeconds) {
    return 1;
  }
  return 0;
}

final class _ClockReadout extends StatelessWidget {
  final Participant participant;
  final TimerSnapshot snapshot;
  final List<TimerFeedbackCue> feedbackCues;
  final bool showOvertime;
  final bool canResume;
  final bool isDark;
  final VoidCallback? onPassTurn;

  const _ClockReadout({
    required this.participant,
    required this.snapshot,
    required this.feedbackCues,
    required this.showOvertime,
    required this.canResume,
    required this.isDark,
    required this.onPassTurn,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = participant.id == snapshot.activeParticipantId;
    final isOvertime = snapshot.phase == TimerPhase.runningOvertime && isActive;
    final foreground = isDark ? CupertinoColors.white : const Color(0xFF111111);
    final muted = isDark ? const Color(0xFFC9C9C9) : const Color(0xFF5F6460);
    final textShadows = [
      Shadow(
        color: isDark ? const Color(0x99000000) : const Color(0x99FFFFFF),
        blurRadius: 10,
      ),
    ];
    final timeText = isActive
        ? isOvertime
              ? showOvertime
                    ? '오버타임 +${formatSeconds(snapshot.currentTurnOvertimeSeconds)}'
                    : '차례 종료'
              : formatSeconds(snapshot.currentTurnRemainingSeconds)
        : formatSeconds(participant.totalRemainingSeconds);

    return Semantics(
      button: onPassTurn != null,
      label: _clockSemanticsLabel(
        participant: participant,
        snapshot: snapshot,
        isActive: isActive,
        showOvertime: showOvertime,
        canResume: canResume,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPassTurn,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 54, 18, 28),
            child: OverflowBox(
              maxWidth: 360,
              child: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      participant.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        shadows: textShadows,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      timeText,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: foreground,
                        fontSize: isOvertime && showOvertime ? 58 : 82,
                        fontWeight: FontWeight.w900,
                        shadows: textShadows,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _panelStatus(
                        participant,
                        snapshot,
                        isActive: isActive,
                        canResume: canResume,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: muted,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: textShadows,
                      ),
                    ),
                    if (isActive && feedbackCues.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _FeedbackBanner(cues: feedbackCues),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ClockControls extends StatelessWidget {
  final TimerPhase phase;
  final bool canResume;
  final VoidCallback onPauseOrResume;
  final VoidCallback onFinish;

  const _ClockControls({
    required this.phase,
    required this.canResume,
    required this.onPauseOrResume,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final canPause =
        phase == TimerPhase.runningNormal ||
        phase == TimerPhase.runningOvertime ||
        (phase == TimerPhase.paused && canResume);
    final isPaused = phase == TimerPhase.paused;
    final pauseKey = isPaused && canResume
        ? const ValueKey('resume-session-button')
        : const ValueKey('pause-session-button');
    final pauseLabel = isPaused && canResume ? '재개' : '일시정지';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: pauseLabel,
          child: CupertinoButton(
            key: pauseKey,
            color: const Color(0xFF303030),
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            onPressed: canPause ? onPauseOrResume : null,
            child: Icon(
              isPaused && canResume
                  ? CupertinoIcons.play_arrow_solid
                  : CupertinoIcons.pause_solid,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: '종료',
          child: CupertinoButton(
            key: const ValueKey('finish-session-button'),
            color: const Color(0xFF303030),
            minimumSize: const Size(48, 48),
            padding: EdgeInsets.zero,
            onPressed: phase == TimerPhase.finished ? null : onFinish,
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

String _panelStatus(
  Participant participant,
  TimerSnapshot snapshot, {
  required bool isActive,
  required bool canResume,
}) {
  if (snapshot.phase == TimerPhase.paused && canResume) {
    return '잠깐 멈춤';
  }
  if (snapshot.phase == TimerPhase.needsExtension && isActive) {
    return '전체 시간이 끝났어요';
  }
  if (isActive) {
    return '말하는 중 · 전체 ${formatSeconds(participant.totalRemainingSeconds)}';
  }
  return '듣는 중';
}

String _clockSemanticsLabel({
  required Participant participant,
  required TimerSnapshot snapshot,
  required bool isActive,
  required bool showOvertime,
  required bool canResume,
}) {
  final parts = <String>[
    participant.name,
    isActive ? '말하는 중' : '듣는 중',
    '전체 남은 시간 ${formatSeconds(participant.totalRemainingSeconds)}',
  ];
  if (isActive) {
    parts.add('이번 차례 ${formatSeconds(snapshot.currentTurnRemainingSeconds)}');
    if (snapshot.phase == TimerPhase.paused && canResume) {
      parts.add('잠깐 멈춤');
    }
    if (snapshot.phase == TimerPhase.runningOvertime) {
      parts.add(
        showOvertime
            ? '오버타임 ${formatSeconds(snapshot.currentTurnOvertimeSeconds)}'
            : '차례 종료',
      );
    }
  }
  return parts.join(', ');
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
