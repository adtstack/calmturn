import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../timer/domain/timer_models.dart';
import 'session_settings.dart';

const sharedTotalMinuteOptions = [
  ChoiceOption('각자 10분', 600),
  ChoiceOption('각자 20분', 1200),
  ChoiceOption('각자 30분', 1800),
  ChoiceOption('각자 60분', 3600),
];

const participantATotalMinuteOptions = [
  ChoiceOption('A 10분', 600),
  ChoiceOption('A 20분', 1200),
  ChoiceOption('A 30분', 1800),
  ChoiceOption('A 60분', 3600),
];

const participantBTotalMinuteOptions = [
  ChoiceOption('B 10분', 600),
  ChoiceOption('B 20분', 1200),
  ChoiceOption('B 30분', 1800),
  ChoiceOption('B 60분', 3600),
];

const turnLimitMinuteOptions = [
  ChoiceOption('턴 1분', 60),
  ChoiceOption('턴 3분', 180),
  ChoiceOption('턴 5분', 300),
  ChoiceOption('턴 10분', 600),
];

final class SessionSetupPage extends StatefulWidget {
  final ValueChanged<SessionConfig> onSessionAccepted;
  final SessionSettingsDraft initialDraft;
  final VoidCallback? onOpenAppSettings;
  final VoidCallback? onOpenHistory;

  SessionSetupPage({
    super.key,
    required this.onSessionAccepted,
    SessionSettingsDraft? initialDraft,
    this.onOpenAppSettings,
    this.onOpenHistory,
  }) : initialDraft = initialDraft ?? SessionSettingsDraft.defaults();

  @override
  State<SessionSetupPage> createState() => _SessionSetupPageState();
}

final class _SessionSetupPageState extends State<SessionSetupPage> {
  final _participantAController = TextEditingController();
  final _participantBController = TextEditingController();

  late SessionSettingsDraft _draft;
  String? _validationMessage;

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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('시계'),
        trailing: widget.onOpenAppSettings == null
            ? null
            : CupertinoButton(
                key: const ValueKey('advanced-settings-button'),
                padding: EdgeInsets.zero,
                onPressed: widget.onOpenAppSettings,
                child: const Icon(CupertinoIcons.gear_alt),
              ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            if (widget.onOpenHistory != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: widget.onOpenHistory,
                  child: const Text('저장된 기록 보기'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _Section(
              title: '참가자',
              children: [
                _FieldLabel('왼쪽'),
                CupertinoTextField(
                  controller: _participantAController,
                  placeholder: '남편',
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _updateDraft(_draft.copyWith(participantAName: value));
                  },
                ),
                const SizedBox(height: 12),
                _FieldLabel('오른쪽'),
                CupertinoTextField(
                  controller: _participantBController,
                  placeholder: '와이프',
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
              title: '첫 발언자',
              children: [
                _ChoiceGroup<String>(
                  value: _draft.firstSpeakerId,
                  options: [
                    ChoiceOption(
                      _nameOrFallback(_draft.participantAName, '남편'),
                      SessionSettingsDraft.participantAId,
                    ),
                    ChoiceOption(
                      _nameOrFallback(_draft.participantBName, '와이프'),
                      SessionSettingsDraft.participantBId,
                    ),
                  ],
                  onSelected: (value) {
                    _updateDraft(_draft.copyWith(firstSpeakerId: value));
                  },
                ),
              ],
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 8),
              ValidationNotice(_validationMessage!),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            CupertinoButton.filled(
              onPressed: _startSession,
              child: const Text('시작'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDraft(SessionSettingsDraft draft) {
    setState(() {
      _draft = draft;
      _validationMessage = null;
    });
  }

  void _handleInvalidInput(String message) {
    setState(() {
      _validationMessage = message;
    });
  }

  void _startSession() {
    final validationMessage = validateSessionSettingsDraft(_draft);
    if (validationMessage != null) {
      setState(() {
        _validationMessage = validationMessage;
      });
      return;
    }

    widget.onSessionAccepted(_draft.toSessionConfig());
  }
}

final class ChoiceOption<T> {
  final String label;
  final T value;

  const ChoiceOption(this.label, this.value);
}

final class MinutePresetField extends StatefulWidget {
  final int value;
  final List<ChoiceOption<int>> options;
  final String inputKey;
  final int minMinutes;
  final int maxMinutes;
  final String rangeMessage;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onInvalidInput;

  const MinutePresetField({
    super.key,
    required this.value,
    required this.options,
    required this.inputKey,
    required this.minMinutes,
    required this.maxMinutes,
    required this.rangeMessage,
    required this.onChanged,
    required this.onInvalidInput,
  });

  @override
  State<MinutePresetField> createState() => _MinutePresetFieldState();
}

final class _MinutePresetFieldState extends State<MinutePresetField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _minutesText(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant MinutePresetField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final nextText = _minutesText(widget.value);
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasPresetValue = widget.options.any((option) {
      return option.value == widget.value;
    });
    final customSelected = !hasPresetValue || _focusNode.hasFocus;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...widget.options.map((option) {
          final isSelected = option.value == widget.value;
          return CupertinoButton(
            minimumSize: const Size(0, 40),
            color: isSelected
                ? const Color(0xFF2D6A64)
                : const Color(0xFFECE7DB),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            onPressed: () {
              widget.onChanged(option.value);
              _focusNode.unfocus();
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
        }),
        GestureDetector(
          key: ValueKey(widget.inputKey.replaceFirst('-field', '-option')),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _focusNode.requestFocus();
            _controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controller.text.length,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: customSelected
                  ? const Color(0xFF2D6A64)
                  : const Color(0xFFECE7DB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '직접 입력',
                    style: TextStyle(
                      color: customSelected
                          ? CupertinoColors.white
                          : const Color(0xFF1C2523),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    child: CupertinoTextField(
                      key: ValueKey(widget.inputKey),
                      focusNode: _focusNode,
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: null,
                      padding: EdgeInsets.zero,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: customSelected
                            ? CupertinoColors.white
                            : const Color(0xFF1C2523),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      cursorColor: customSelected
                          ? CupertinoColors.white
                          : const Color(0xFF2D6A64),
                      onChanged: (value) {
                        final minutes = int.tryParse(value);
                        if (minutes == null || value.isEmpty) {
                          return;
                        }
                        if (minutes < widget.minMinutes ||
                            minutes > widget.maxMinutes) {
                          widget.onInvalidInput(widget.rangeMessage);
                          return;
                        }
                        widget.onChanged(minutes * 60);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '분',
                    style: TextStyle(
                      color: customSelected
                          ? CupertinoColors.white
                          : const Color(0xFF1C2523),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _minutesText(int seconds) {
  if (seconds % 60 != 0) {
    return '';
  }
  return '${seconds ~/ 60}';
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

final class ValidationNotice extends StatelessWidget {
  final String text;

  const ValidationNotice(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0A58D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9A3B23),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String formatSeconds(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = seconds % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}

String _nameOrFallback(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
