import 'package:flutter/cupertino.dart';

import '../timer/domain/timer_models.dart';
import 'session_settings.dart';

final class SessionSetupPage extends StatefulWidget {
  final ValueChanged<SessionConfig> onSessionAccepted;
  final SessionSettingsDraft initialDraft;
  final VoidCallback? onOpenAppSettings;

  SessionSetupPage({
    super.key,
    required this.onSessionAccepted,
    SessionSettingsDraft? initialDraft,
    this.onOpenAppSettings,
  }) : initialDraft = initialDraft ?? SessionSettingsDraft.defaults();

  @override
  State<SessionSetupPage> createState() => _SessionSetupPageState();
}

final class _SessionSetupPageState extends State<SessionSetupPage> {
  final _participantAController = TextEditingController();
  final _participantBController = TextEditingController();

  late SessionSettingsDraft _draft;
  bool _isReviewing = false;
  bool _participantAAgreed = false;
  bool _participantBAgreed = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
    _participantAController.text = _draft.participantAName;
    _participantBController.text = _draft.participantBName;
  }

  @override
  void dispose() {
    _participantAController.dispose();
    _participantBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isReviewing) {
      return _ConsentView(
        config: _draft.toSessionConfig(),
        participantAAgreed: _participantAAgreed,
        participantBAgreed: _participantBAgreed,
        onBack: () {
          setState(() {
            _isReviewing = false;
          });
        },
        onParticipantAAgreed: () {
          setState(() {
            _participantAAgreed = !_participantAAgreed;
          });
        },
        onParticipantBAgreed: () {
          setState(() {
            _participantBAgreed = !_participantBAgreed;
          });
        },
        onStart: () {
          widget.onSessionAccepted(_draft.toSessionConfig());
        },
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('대화 규칙'),
        trailing: widget.onOpenAppSettings == null
            ? null
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onOpenAppSettings,
                child: const Text('앱 설정'),
              ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _Section(
              title: '참가자',
              children: [
                _FieldLabel('A'),
                CupertinoTextField(
                  controller: _participantAController,
                  placeholder: '말하는 사람 A',
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(participantAName: value));
                  },
                ),
                const SizedBox(height: 12),
                _FieldLabel('B'),
                CupertinoTextField(
                  controller: _participantBController,
                  placeholder: '말하는 사람 B',
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(participantBName: value));
                  },
                ),
              ],
            ),
            _Section(
              title: '전체 시간',
              children: [
                if (_draft.totalTimeMode == TotalTimeMode.same)
                  _ChoiceGroup<int>(
                    value: _draft.sharedTotalSeconds,
                    options: const [
                      ChoiceOption('각자 3분', 180),
                      ChoiceOption('각자 5분', 300),
                      ChoiceOption('각자 10분', 600),
                      ChoiceOption('각자 15분', 900),
                    ],
                    onSelected: (value) {
                      _updateDraft(_draft.copyWith(sharedTotalSeconds: value));
                    },
                  )
                else ...[
                  _ChoiceGroup<int>(
                    value: _draft.participantATotalSeconds,
                    options: const [
                      ChoiceOption('A 3분', 180),
                      ChoiceOption('A 5분', 300),
                      ChoiceOption('A 7분', 420),
                      ChoiceOption('A 10분', 600),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(participantATotalSeconds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _ChoiceGroup<int>(
                    value: _draft.participantBTotalSeconds,
                    options: const [
                      ChoiceOption('B 3분', 180),
                      ChoiceOption('B 5분', 300),
                      ChoiceOption('B 7분', 420),
                      ChoiceOption('B 10분', 600),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(participantBTotalSeconds: value),
                      );
                    },
                  ),
                ],
              ],
            ),
            _Section(
              title: '턴 제한',
              children: [
                _ChoiceGroup<int>(
                  value: _draft.turnLimitSeconds,
                  options: const [
                    ChoiceOption('턴 30초', 30),
                    ChoiceOption('턴 45초', 45),
                    ChoiceOption('턴 1분', 60),
                    ChoiceOption('턴 1분 30초', 90),
                    ChoiceOption('턴 2분', 120),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(turnLimitSeconds: value));
                  },
                ),
              ],
            ),
            _Section(
              title: '첫 발언자',
              children: [
                _ChoiceGroup<String>(
                  value: _draft.firstSpeakerId,
                  options: [
                    ChoiceOption(
                      _nameOrFallback(_draft.participantAName, '말하는 사람 A'),
                      SessionSettingsDraft.participantAId,
                    ),
                    ChoiceOption(
                      _nameOrFallback(_draft.participantBName, '말하는 사람 B'),
                      SessionSettingsDraft.participantBId,
                    ),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(firstSpeakerId: value));
                  },
                ),
              ],
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                setState(() {
                  _showAdvanced = !_showAdvanced;
                });
              },
              child: Text(_showAdvanced ? '고급 설정 닫기' : '고급 설정'),
            ),
            if (_showAdvanced) ...[
              _Section(
                title: '시간 배분',
                children: [
                  _ChoiceGroup<TotalTimeMode>(
                    value: _draft.totalTimeMode,
                    options: const [
                      ChoiceOption('같은 시간', TotalTimeMode.same),
                      ChoiceOption(
                        '각자 다르게',
                        TotalTimeMode.customPerParticipant,
                      ),
                    ],
                    onSelected: (value) {
                      _updateDraft(_draft.copyWith(totalTimeMode: value));
                    },
                  ),
                  if (_draft.totalTimeMode ==
                      TotalTimeMode.customPerParticipant) ...[
                    const SizedBox(height: 14),
                    _ChoiceGroup<int>(
                      value: _draft.participantATotalSeconds,
                      options: const [
                        ChoiceOption('A 3분', 180),
                        ChoiceOption('A 5분', 300),
                        ChoiceOption('A 7분', 420),
                        ChoiceOption('A 10분', 600),
                      ],
                      onSelected: (value) {
                        _updateDraft(
                          _draft.copyWith(participantATotalSeconds: value),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _ChoiceGroup<int>(
                      value: _draft.participantBTotalSeconds,
                      options: const [
                        ChoiceOption('B 3분', 180),
                        ChoiceOption('B 5분', 300),
                        ChoiceOption('B 7분', 420),
                        ChoiceOption('B 10분', 600),
                      ],
                      onSelected: (value) {
                        _updateDraft(
                          _draft.copyWith(participantBTotalSeconds: value),
                        );
                      },
                    ),
                  ],
                ],
              ),
              _Section(
                title: '오버타임',
                children: [
                  _ToggleRow(
                    label: '오버타임',
                    value: _draft.overtimeEnabled,
                    onChanged: (value) {
                      _updateDraft(
                        _draft.copyWith(
                          overtimeEnabled: value,
                          showOvertime: value,
                        ),
                      );
                    },
                  ),
                  _ToggleRow(
                    label: '오버타임 표시',
                    value: _draft.showOvertime,
                    onChanged: _draft.overtimeEnabled
                        ? (value) {
                            _updateDraft(_draft.copyWith(showOvertime: value));
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _ChoiceGroup<int>(
                    value: _draft.penaltyThresholdSeconds,
                    options: const [
                      ChoiceOption('주의 표시 30초', 30),
                      ChoiceOption('주의 표시 1분', 60),
                      ChoiceOption('주의 표시 2분', 120),
                      ChoiceOption('주의 표시 3분', 180),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(penaltyThresholdSeconds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ToggleRow(
                    label: '주의 표시 반복',
                    value:
                        _draft.penaltyRepeatMode ==
                        PenaltyRepeatMode.everyThreshold,
                    onChanged: (value) {
                      _updateDraft(
                        _draft.copyWith(
                          penaltyRepeatMode: value
                              ? PenaltyRepeatMode.everyThreshold
                              : PenaltyRepeatMode.oncePerTurn,
                        ),
                      );
                    },
                  ),
                ],
              ),
              _Section(
                title: '알림',
                children: [
                  _ChoiceGroup<int>(
                    value: _draft.warningBeforeSeconds,
                    options: const [
                      ChoiceOption('5초 전', 5),
                      ChoiceOption('10초 전', 10),
                      ChoiceOption('15초 전', 15),
                      ChoiceOption('30초 전', 30),
                    ],
                    onSelected: (value) {
                      _updateDraft(
                        _draft.copyWith(warningBeforeSeconds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ToggleRow(
                    label: '턴 시간',
                    value: _draft.turnWarningEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(turnWarningEnabled: value));
                    },
                  ),
                  _ToggleRow(
                    label: '전체 시간',
                    value: _draft.totalWarningEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(totalWarningEnabled: value));
                    },
                  ),
                  _ToggleRow(
                    label: '오버타임 시작',
                    value: _draft.overtimeStartAlertEnabled,
                    onChanged: (value) {
                      _updateDraft(
                        _draft.copyWith(overtimeStartAlertEnabled: value),
                      );
                    },
                  ),
                  _ToggleRow(
                    label: '주의 표시',
                    value: _draft.penaltyAlertEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(penaltyAlertEnabled: value));
                    },
                  ),
                  const SizedBox(height: 12),
                  _ToggleRow(
                    label: '화면',
                    value: _draft.visualEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(visualEnabled: value));
                    },
                  ),
                  _ToggleRow(
                    label: '소리',
                    value: _draft.soundEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(soundEnabled: value));
                    },
                  ),
                  _ToggleRow(
                    label: '진동',
                    value: _draft.hapticEnabled,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(hapticEnabled: value));
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            CupertinoButton.filled(
              onPressed: () {
                setState(() {
                  _participantAAgreed = false;
                  _participantBAgreed = false;
                  _isReviewing = true;
                });
              },
              child: const Text('규칙 확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDraft(SessionSettingsDraft draft) {
    setState(() {
      _draft = draft;
    });
  }
}

final class _ConsentView extends StatelessWidget {
  final SessionConfig config;
  final bool participantAAgreed;
  final bool participantBAgreed;
  final VoidCallback onBack;
  final VoidCallback onParticipantAAgreed;
  final VoidCallback onParticipantBAgreed;
  final VoidCallback onStart;

  const _ConsentView({
    required this.config,
    required this.participantAAgreed,
    required this.participantBAgreed,
    required this.onBack,
    required this.onParticipantAAgreed,
    required this.onParticipantBAgreed,
    required this.onStart,
  });

  bool get _canStart => participantAAgreed && participantBAgreed;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('규칙 확인'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onBack,
          child: const Text('수정'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const Text(
              '두 사람이 같은 규칙을 보고 시작해요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              '내 차례에는 말하고, 상대 차례에는 들어요. 불편하면 언제든 잠깐 쉴 수 있어요.',
              style: TextStyle(color: Color(0xFF5F6964), fontSize: 15),
            ),
            const SizedBox(height: 18),
            _Section(
              title: '오늘의 규칙',
              children: [
                _RuleLine(
                  '${config.participantA.name} 전체 시간: '
                  '${formatSeconds(config.participantA.totalAllocatedSeconds)}',
                ),
                _RuleLine(
                  '${config.participantB.name} 전체 시간: '
                  '${formatSeconds(config.participantB.totalAllocatedSeconds)}',
                ),
                _RuleLine('턴 제한: ${formatSeconds(config.turnLimitSeconds)}'),
                _RuleLine(
                  '오버타임: ${config.overtimeConfig.enabled ? '사용' : '사용 안 함'}',
                ),
                _RuleLine(
                  '주의 표시 기준: '
                  '${formatSeconds(config.penaltyConfig.thresholdSeconds)}',
                ),
                _RuleLine('알림: ${alertMethodsLabel(config.alertConfig)}'),
                _RuleLine(
                  '첫 발언자: '
                  '${_participantName(config, config.firstSpeakerId)}',
                ),
              ],
            ),
            if (config.participantA.totalAllocatedSeconds !=
                config.participantB.totalAllocatedSeconds) ...[
              const SizedBox(height: 12),
              const _Notice(
                '이번 대화는 서로 다른 전체 시간으로 설정되어 있어요. 서로 동의한 시간 배분인지 확인해주세요.',
              ),
            ],
            const SizedBox(height: 16),
            _AgreementButton(
              label: '${config.participantA.name} 동의',
              agreed: participantAAgreed,
              onPressed: onParticipantAAgreed,
            ),
            const SizedBox(height: 10),
            _AgreementButton(
              label: '${config.participantB.name} 동의',
              agreed: participantBAgreed,
              onPressed: onParticipantBAgreed,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              key: const ValueKey('start-timer-button'),
              onPressed: _canStart ? onStart : null,
              child: const Text('타이머 시작'),
            ),
          ],
        ),
      ),
    );
  }
}

final class ChoiceOption<T> {
  final String label;
  final T value;

  const ChoiceOption(this.label, this.value);
}

final class _ChoiceGroup<T> extends StatelessWidget {
  final T value;
  final List<ChoiceOption<T>> options;
  final ValueChanged<T> onSelected;

  const _ChoiceGroup({
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option.value == value;
        return CupertinoButton(
          minimumSize: const Size(0, 40),
          color: isSelected ? const Color(0xFF2D6A64) : const Color(0xFFECE7DB),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          onPressed: () {
            onSelected(option.value);
          },
          child: Text(
            option.label,
            style: TextStyle(
              color: isSelected
                  ? CupertinoColors.white
                  : const Color(0xFF1C2523),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}

final class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              onChanged?.call(!value);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFF1C2523)
                      : const Color(0xFF929A95),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CupertinoSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

final class _AgreementButton extends StatelessWidget {
  final String label;
  final bool agreed;
  final VoidCallback onPressed;

  const _AgreementButton({
    required this.label,
    required this.agreed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: agreed ? const Color(0xFF2D6A64) : const Color(0xFFECE7DB),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: agreed ? CupertinoColors.white : const Color(0xFF1C2523),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9D4C8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

final class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF5F6964),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final class _RuleLine extends StatelessWidget {
  final String text;

  const _RuleLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

final class _Notice extends StatelessWidget {
  final String text;

  const _Notice(this.text);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: Text(text)),
    );
  }
}

String formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String alertMethodsLabel(AlertConfig config) {
  final methods = <String>[
    if (config.visualEnabled) '화면',
    if (config.soundEnabled) '소리',
    if (config.hapticEnabled) '진동',
  ];

  return methods.isEmpty ? '꺼짐' : methods.join(' + ');
}

String _nameOrFallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _participantName(SessionConfig config, String id) {
  if (config.participantA.id == id) {
    return config.participantA.name;
  }
  return config.participantB.name;
}
