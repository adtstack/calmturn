import 'package:flutter/cupertino.dart';

import '../settings/session_setup_page.dart';
import 'history_screen.dart';
import 'session_record.dart';
import 'session_record_store.dart';

final class WrapUpPage extends StatefulWidget {
  final SessionRecord draftRecord;
  final SessionRecordStore recordStore;
  final bool recordWasAutoSaved;
  final VoidCallback onStartAnotherSession;

  const WrapUpPage({
    super.key,
    required this.draftRecord,
    required this.recordStore,
    this.recordWasAutoSaved = false,
    required this.onStartAnotherSession,
  });

  @override
  State<WrapUpPage> createState() => _WrapUpPageState();
}

final class _WrapUpPageState extends State<WrapUpPage> {
  late final TextEditingController _summaryController;
  late final TextEditingController _tagInputController;
  late List<String> _selectedTags;
  List<String> _recentTags = const [];
  ConversationOutcome _outcome = ConversationOutcome.resolved;
  String? _statusMessage;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController(
      text: widget.draftRecord.summaryText,
    );
    _tagInputController = TextEditingController();
    _selectedTags = _tagsFromText(widget.draftRecord.tagsText);
    _outcome = widget.draftRecord.outcome ?? ConversationOutcome.resolved;
    _loadRecentTags();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentTags() async {
    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    final tags = <String>[];
    final seen = <String>{};
    for (final record in records) {
      if (record.id == widget.draftRecord.id) {
        continue;
      }
      for (final tag in _tagsFromText(record.tagsText)) {
        if (seen.add(tag)) {
          tags.add(tag);
        }
      }
    }
    setState(() {
      _recentTags = tags;
    });
  }

  Future<void> _saveRecord() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    final record = widget.draftRecord.withWrapUpDetails(
      summaryText: _summaryController.text,
      tagsText: _tagsTextForSave(),
      outcome: _outcome,
    );
    await widget.recordStore.save(record);
    if (!mounted) {
      return;
    }
    widget.onStartAnotherSession();
  }

  Future<void> _finishWithoutSaving() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    if (widget.recordWasAutoSaved) {
      await widget.recordStore.delete(widget.draftRecord.id);
    }
    if (!mounted) {
      return;
    }
    widget.onStartAnotherSession();
  }

  void _openHistory() {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) {
          return HistoryScreen(recordStore: widget.recordStore);
        },
      ),
    );
  }

  void _handleTagInputChanged(String value) {
    if (!_hasWhitespace(value)) {
      return;
    }
    _addTags(_tagsFromText(value));
    _tagInputController.clear();
  }

  void _addTags(Iterable<String> tags) {
    final next = _mergeTags([..._selectedTags, ...tags]);
    setState(() {
      _selectedTags = next;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags = _selectedTags.where((item) => item != tag).toList();
    });
  }

  String? _tagsTextForSave() {
    final tags = _mergeTags([
      ..._selectedTags,
      ..._tagsFromText(_tagInputController.text),
    ]);
    return tags.isEmpty ? null : tags.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.draftRecord;
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('마무리')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
          children: [
            const Text(
              '대화를 마쳤어요.',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘 나눈 마음을 정리해요.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('모든 대화는 관계가 나아지는 연습이 될 수 있어요.'),
            const SizedBox(height: 18),
            _SummaryCard(record: record),
            const SizedBox(height: 14),
            ...record.participantResults.map((participant) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ParticipantResultCard(participant: participant),
              );
            }),
            const SizedBox(height: 12),
            _NotesSection(
              summaryController: _summaryController,
              tagInputController: _tagInputController,
              selectedTags: _selectedTags,
              recentTags: _recentTags,
              onTagInputChanged: _handleTagInputChanged,
              onAddTag: (tag) => _addTags([tag]),
              onRemoveTag: _removeTag,
              outcome: _outcome,
              onOutcomeChanged: (outcome) {
                setState(() {
                  _outcome = outcome;
                });
              },
            ),
            const SizedBox(height: 14),
            CupertinoButton.filled(
              onPressed: _isBusy ? null : _saveRecord,
              child: const Text('기록 저장'),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              onPressed: _isBusy ? null : _finishWithoutSaving,
              child: const Text('저장하지 않고 마치기'),
            ),
            CupertinoButton(
              onPressed: widget.onStartAnotherSession,
              child: const Text('설정으로 돌아가기'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _StatusLine(_statusMessage!),
            ],
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: _openHistory,
              child: const Text('기록 보기'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  final SessionRecord record;

  const _SummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요약',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData('대화 시간', formatSeconds(record.durationSeconds)),
              _MetricData('휴식', record.breakCount.toString()),
              _MetricData('휴식 시간', formatSeconds(record.totalBreakSeconds)),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ParticipantResultCard extends StatelessWidget {
  final ParticipantResult participant;

  const _ParticipantResultCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participant.displayName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                '사용한 시간',
                formatSeconds(participant.totalUsedSeconds),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _NotesSection extends StatelessWidget {
  final TextEditingController summaryController;
  final TextEditingController tagInputController;
  final List<String> selectedTags;
  final List<String> recentTags;
  final ValueChanged<String> onTagInputChanged;
  final ValueChanged<String> onAddTag;
  final ValueChanged<String> onRemoveTag;
  final ConversationOutcome outcome;
  final ValueChanged<ConversationOutcome> onOutcomeChanged;

  const _NotesSection({
    required this.summaryController,
    required this.tagInputController,
    required this.selectedTags,
    required this.recentTags,
    required this.onTagInputChanged,
    required this.onAddTag,
    required this.onRemoveTag,
    required this.outcome,
    required this.onOutcomeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '기록',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('총평'),
          CupertinoTextField(
            key: const ValueKey('summary-text-field'),
            controller: summaryController,
            minLines: 2,
            maxLines: 4,
            placeholder: '대화를 짧게 정리해두세요',
          ),
          const SizedBox(height: 12),
          const _FieldLabel('해시태그'),
          if (recentTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentTags
                  .map((tag) {
                    return _TagSuggestionChip(
                      tag: tag,
                      onTap: () => onAddTag(tag),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
          ],
          if (selectedTags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedTags
                  .map((tag) {
                    return _SelectedTagChip(
                      tag: tag,
                      onRemove: () => onRemoveTag(tag),
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
          ],
          CupertinoTextField(
            key: const ValueKey('tags-text-field'),
            controller: tagInputController,
            onChanged: onTagInputChanged,
            minLines: 1,
            maxLines: 1,
            placeholder: '감정 생활비',
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          _OutcomeSelector(outcome: outcome, onChanged: onOutcomeChanged),
        ],
      ),
    );
  }
}

final class _TagSuggestionChip extends StatelessWidget {
  final String tag;
  final VoidCallback onTap;

  const _TagSuggestionChip({required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey('recent-tag-$tag'),
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: const Color(0xFFE7F1EC),
      borderRadius: BorderRadius.circular(8),
      onPressed: onTap,
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFF244F4B),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final class _SelectedTagChip extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const _SelectedTagChip({required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('selected-tag-$tag'),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 7, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: CupertinoColors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _OutcomeSelector extends StatelessWidget {
  final ConversationOutcome outcome;
  final ValueChanged<ConversationOutcome> onChanged;

  const _OutcomeSelector({required this.outcome, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ConversationOutcome.values
          .map((value) {
            final selected = value == outcome;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CupertinoButton(
                  color: selected
                      ? const Color(0xFF111111)
                      : const Color(0xFFE9E9E4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => onChanged(value),
                  child: Text(
                    value.label,
                    style: TextStyle(
                      color: selected
                          ? CupertinoColors.white
                          : const Color(0xFF111111),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

List<String> _tagsFromText(String? text) {
  if (text == null) {
    return const [];
  }
  final tags = text
      .split(RegExp(r'\s+'))
      .map(_normalizeTag)
      .whereType<String>()
      .toList(growable: false);
  return _mergeTags(tags);
}

List<String> _mergeTags(Iterable<String> tags) {
  final merged = <String>[];
  final seen = <String>{};
  for (final tag in tags) {
    final normalized = _normalizeTag(tag);
    if (normalized != null && seen.add(normalized)) {
      merged.add(normalized);
    }
  }
  return merged;
}

String? _normalizeTag(String value) {
  final trimmed = value.trim().replaceAll(RegExp(r'^#+'), '');
  if (trimmed.isEmpty) {
    return null;
  }
  return '#$trimmed';
}

bool _hasWhitespace(String value) {
  return RegExp(r'\s').hasMatch(value);
}

final class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9D4C8)),
      ),
      child: child,
    );
  }
}

final class _MetricData {
  final String label;
  final String value;

  const _MetricData(this.label, this.value);
}

final class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 12,
      children: metrics
          .map((metric) {
            return SizedBox(
              width: 136,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.label,
                    style: const TextStyle(
                      color: Color(0xFF6D746F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

final class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

final class _StatusLine extends StatelessWidget {
  final String text;

  const _StatusLine(this.text);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
