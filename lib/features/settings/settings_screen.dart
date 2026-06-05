import 'package:flutter/cupertino.dart';

import '../history/session_record_store.dart';
import '../timer/domain/timer_models.dart';
import 'app_settings.dart';
import 'session_setup_page.dart';
import 'session_settings.dart';

final class SettingsScreen extends StatefulWidget {
  final AppSettingsDraft settings;
  final ValueChanged<AppSettingsDraft> onSettingsChanged;
  final VoidCallback onBack;
  final SessionRecordStore recordStore;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onBack,
    required this.recordStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettingsDraft _settings;
  bool _isBusy = false;
  String? _statusMessage;
  String? _validationMessage;

  SessionSettingsDraft get _draft => _settings.sessionDefaults;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('설정'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: widget.onBack,
          child: const Text('대화 규칙으로'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            const Text(
              '앱 설정',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              '다음 대화를 시작할 때 사용할 기본 규칙입니다.',
              style: TextStyle(color: Color(0xFF5F6964)),
            ),
            const SizedBox(height: 18),
            _Section(
              title: '전체 시간',
              children: [
                _ChoiceGroup<TotalTimeMode>(
                  value: _draft.totalTimeMode,
                  options: const [
                    ChoiceOption('같은 시간', TotalTimeMode.same),
                    ChoiceOption('각자 다르게', TotalTimeMode.customPerParticipant),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(totalTimeMode: value));
                  },
                ),
                const SizedBox(height: 14),
                if (_draft.totalTimeMode == TotalTimeMode.same)
                  MinutePresetField(
                    value: _draft.sharedTotalSeconds,
                    options: sharedTotalMinuteOptions,
                    inputKey: 'shared-total-minutes-field',
                    minMinutes: minTotalMinutes,
                    maxMinutes: maxTotalMinutes,
                    rangeMessage: invalidTotalTimeRangeMessage,
                    onInvalidInput: _handleInvalidInput,
                    onChanged: (value) {
                      _updateDraft(_draft.copyWith(sharedTotalSeconds: value));
                    },
                  )
                else ...[
                  MinutePresetField(
                    value: _draft.participantATotalSeconds,
                    options: participantATotalMinuteOptions,
                    inputKey: 'participant-a-total-minutes-field',
                    minMinutes: minTotalMinutes,
                    maxMinutes: maxTotalMinutes,
                    rangeMessage: invalidTotalTimeRangeMessage,
                    onInvalidInput: _handleInvalidInput,
                    onChanged: (value) {
                      _updateDraft(
                        _draft.copyWith(participantATotalSeconds: value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  MinutePresetField(
                    value: _draft.participantBTotalSeconds,
                    options: participantBTotalMinuteOptions,
                    inputKey: 'participant-b-total-minutes-field',
                    minMinutes: minTotalMinutes,
                    maxMinutes: maxTotalMinutes,
                    rangeMessage: invalidTotalTimeRangeMessage,
                    onInvalidInput: _handleInvalidInput,
                    onChanged: (value) {
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
                MinutePresetField(
                  value: _draft.turnLimitSeconds,
                  options: turnLimitMinuteOptions,
                  inputKey: 'turn-limit-minutes-field',
                  minMinutes: minTurnLimitMinutes,
                  maxMinutes: maxTurnLimitMinutes,
                  rangeMessage: invalidTurnLimitRangeMessage,
                  onInvalidInput: _handleInvalidInput,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(turnLimitSeconds: value));
                  },
                ),
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
                if (_draft.overtimeEnabled) ...[
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
                    _updateDraft(_draft.copyWith(warningBeforeSeconds: value));
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
                if (_draft.overtimeEnabled) ...[
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
                ],
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
            _Section(
              title: '기록',
              children: [
                _ToggleRow(
                  label: '자동 저장',
                  value: _settings.autoSaveRecords,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(autoSaveRecords: value);
                      _statusMessage = null;
                      _validationMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  color: CupertinoColors.systemRed,
                  onPressed: _isBusy ? null : _clearRecords,
                  child: const Text('모든 기록 삭제'),
                ),
              ],
            ),
            CupertinoButton.filled(
              onPressed: _saveSettings,
              child: const Text('설정 저장'),
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 12),
              ValidationNotice(_validationMessage!),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _StatusLine(_statusMessage!),
            ],
          ],
        ),
      ),
    );
  }

  void _updateDraft(SessionSettingsDraft draft) {
    setState(() {
      _settings = _settings.copyWith(sessionDefaults: draft);
      _statusMessage = null;
      _validationMessage = null;
    });
  }

  void _handleInvalidInput(String message) {
    setState(() {
      _statusMessage = null;
      _validationMessage = message;
    });
  }

  void _saveSettings() {
    final validationMessage = validateSessionSettingsDraft(_draft);
    if (validationMessage != null) {
      setState(() {
        _validationMessage = validationMessage;
        _statusMessage = null;
      });
      return;
    }

    widget.onSettingsChanged(_settings);
    setState(() {
      _validationMessage = null;
      _statusMessage = '다음 대화에 사용할 설정을 저장했어요.';
    });
  }

  Future<void> _clearRecords() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
      _validationMessage = null;
    });
    await widget.recordStore.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _statusMessage = '모든 기록을 삭제했어요.';
    });
  }
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

final class _StatusLine extends StatelessWidget {
  final String text;

  const _StatusLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF2D6A64),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
