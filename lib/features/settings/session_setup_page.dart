import 'package:flutter/cupertino.dart';

import '../timer/domain/timer_models.dart';
import 'session_settings.dart';

final class SessionSetupPage extends StatefulWidget {
  final ValueChanged<SessionConfig> onSessionAccepted;

  const SessionSetupPage({super.key, required this.onSessionAccepted});

  @override
  State<SessionSetupPage> createState() => _SessionSetupPageState();
}

final class _SessionSetupPageState extends State<SessionSetupPage> {
  final _participantAController = TextEditingController();
  final _participantBController = TextEditingController();

  SessionSettingsDraft _draft = SessionSettingsDraft.defaults();
  bool _isReviewing = false;
  bool _participantAAgreed = false;
  bool _participantBAgreed = false;

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
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Session Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            _Section(
              title: 'Participants',
              children: [
                _FieldLabel('Participant A'),
                CupertinoTextField(
                  controller: _participantAController,
                  placeholder: 'Speaker A',
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(participantAName: value));
                  },
                ),
                const SizedBox(height: 12),
                _FieldLabel('Participant B'),
                CupertinoTextField(
                  controller: _participantBController,
                  placeholder: 'Speaker B',
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(participantBName: value));
                  },
                ),
              ],
            ),
            _Section(
              title: 'Speaking Time',
              children: [
                _ChoiceGroup<TotalTimeMode>(
                  value: _draft.totalTimeMode,
                  options: const [
                    ChoiceOption('Same', TotalTimeMode.same),
                    ChoiceOption(
                      'Different',
                      TotalTimeMode.customPerParticipant,
                    ),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(totalTimeMode: value));
                  },
                ),
                const SizedBox(height: 14),
                if (_draft.totalTimeMode == TotalTimeMode.same)
                  _ChoiceGroup<int>(
                    value: _draft.sharedTotalSeconds,
                    options: const [
                      ChoiceOption('3 min each', 180),
                      ChoiceOption('5 min each', 300),
                      ChoiceOption('10 min each', 600),
                      ChoiceOption('15 min each', 900),
                    ],
                    onSelected: (value) {
                      _updateDraft(_draft.copyWith(sharedTotalSeconds: value));
                    },
                  )
                else ...[
                  _ChoiceGroup<int>(
                    value: _draft.participantATotalSeconds,
                    options: const [
                      ChoiceOption('A 3 min', 180),
                      ChoiceOption('A 5 min', 300),
                      ChoiceOption('A 7 min', 420),
                      ChoiceOption('A 10 min', 600),
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
                      ChoiceOption('B 3 min', 180),
                      ChoiceOption('B 5 min', 300),
                      ChoiceOption('B 7 min', 420),
                      ChoiceOption('B 10 min', 600),
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
              title: 'Turn Limit',
              children: [
                _ChoiceGroup<int>(
                  value: _draft.turnLimitSeconds,
                  options: const [
                    ChoiceOption('Turn 30 sec', 30),
                    ChoiceOption('Turn 45 sec', 45),
                    ChoiceOption('Turn 1 min', 60),
                    ChoiceOption('Turn 90 sec', 90),
                    ChoiceOption('Turn 2 min', 120),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(turnLimitSeconds: value));
                  },
                ),
              ],
            ),
            _Section(
              title: 'Overtime & Marks',
              children: [
                _ToggleRow(
                  label: 'Overtime',
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
                  label: 'Show overtime',
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
                    ChoiceOption('Overtime 30 sec', 30),
                    ChoiceOption('Overtime 1 min', 60),
                    ChoiceOption('Overtime 2 min', 120),
                    ChoiceOption('Overtime 3 min', 180),
                  ],
                  onSelected: (value) {
                    _updateDraft(
                      _draft.copyWith(penaltyThresholdSeconds: value),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Repeat marks',
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
              title: 'Alerts',
              children: [
                _ChoiceGroup<int>(
                  value: _draft.warningBeforeSeconds,
                  options: const [
                    ChoiceOption('Warn 5 sec', 5),
                    ChoiceOption('Warn 10 sec', 10),
                    ChoiceOption('Warn 15 sec', 15),
                    ChoiceOption('Warn 30 sec', 30),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(warningBeforeSeconds: value));
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Turn time',
                  value: _draft.turnWarningEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(turnWarningEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Total time',
                  value: _draft.totalWarningEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(totalWarningEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Overtime start',
                  value: _draft.overtimeStartAlertEnabled,
                  onChanged: (value) {
                    _updateDraft(
                      _draft.copyWith(overtimeStartAlertEnabled: value),
                    );
                  },
                ),
                _ToggleRow(
                  label: 'Overtime mark',
                  value: _draft.penaltyAlertEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(penaltyAlertEnabled: value));
                  },
                ),
                const SizedBox(height: 12),
                _ToggleRow(
                  label: 'Screen',
                  value: _draft.visualEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(visualEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Sound',
                  value: _draft.soundEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(soundEnabled: value));
                  },
                ),
                _ToggleRow(
                  label: 'Vibration',
                  value: _draft.hapticEnabled,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(hapticEnabled: value));
                  },
                ),
              ],
            ),
            _Section(
              title: 'First Speaker',
              children: [
                _ChoiceGroup<String>(
                  value: _draft.firstSpeakerId,
                  options: [
                    ChoiceOption(
                      _nameOrFallback(
                        _draft.participantAName,
                        'Speaker A first',
                      ),
                      SessionSettingsDraft.participantAId,
                    ),
                    ChoiceOption(
                      _nameOrFallback(
                        _draft.participantBName,
                        'Speaker B first',
                      ),
                      SessionSettingsDraft.participantBId,
                    ),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(firstSpeakerId: value));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            CupertinoButton.filled(
              onPressed: () {
                setState(() {
                  _participantAAgreed = false;
                  _participantBAgreed = false;
                  _isReviewing = true;
                });
              },
              child: const Text('Review rules'),
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
        middle: const Text('Consent'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onBack,
          child: const Text('Edit'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const Text(
              '서로 동의한 시간 배분',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Both people review the same rules before the timer starts.',
              style: TextStyle(color: Color(0xFF5F6964), fontSize: 15),
            ),
            const SizedBox(height: 18),
            _Section(
              title: 'Rules',
              children: [
                _RuleLine(
                  '${config.participantA.name} total: '
                  '${formatSeconds(config.participantA.totalAllocatedSeconds)}',
                ),
                _RuleLine(
                  '${config.participantB.name} total: '
                  '${formatSeconds(config.participantB.totalAllocatedSeconds)}',
                ),
                _RuleLine(
                  'Turn limit: ${formatSeconds(config.turnLimitSeconds)}',
                ),
                _RuleLine(
                  'Overtime: ${config.overtimeConfig.enabled ? 'On' : 'Off'}',
                ),
                _RuleLine(
                  'Overtime mark: '
                  '${formatSeconds(config.penaltyConfig.thresholdSeconds)}',
                ),
                _RuleLine('Alerts: ${alertMethodsLabel(config.alertConfig)}'),
                _RuleLine(
                  'First speaker: '
                  '${_participantName(config, config.firstSpeakerId)}',
                ),
              ],
            ),
            if (config.participantA.totalAllocatedSeconds !=
                config.participantB.totalAllocatedSeconds) ...[
              const SizedBox(height: 12),
              const _Notice(
                'This session uses different total speaking times. '
                'Both people should confirm the allocation before starting.',
              ),
            ],
            const SizedBox(height: 16),
            _AgreementButton(
              label: '${config.participantA.name} agrees',
              agreed: participantAAgreed,
              onPressed: onParticipantAAgreed,
            ),
            const SizedBox(height: 10),
            _AgreementButton(
              label: '${config.participantB.name} agrees',
              agreed: participantBAgreed,
              onPressed: onParticipantBAgreed,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              key: const ValueKey('start-timer-button'),
              onPressed: _canStart ? onStart : null,
              child: const Text('Start Timer'),
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
    if (config.visualEnabled) 'Screen',
    if (config.soundEnabled) 'Sound',
    if (config.hapticEnabled) 'Vibration',
  ];

  return methods.isEmpty ? 'Off' : methods.join(' + ');
}

String _nameOrFallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : '$trimmed first';
}

String _participantName(SessionConfig config, String id) {
  if (config.participantA.id == id) {
    return config.participantA.name;
  }
  return config.participantB.name;
}
