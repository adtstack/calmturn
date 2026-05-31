import 'package:flutter/cupertino.dart';

import '../settings/session_setup_page.dart';
import 'session_record.dart';
import 'session_record_store.dart';

final class WrapUpPage extends StatefulWidget {
  final SessionRecord draftRecord;
  final SessionRecordStore recordStore;
  final VoidCallback onStartAnotherSession;

  const WrapUpPage({
    super.key,
    required this.draftRecord,
    required this.recordStore,
    required this.onStartAnotherSession,
  });

  @override
  State<WrapUpPage> createState() => _WrapUpPageState();
}

final class _WrapUpPageState extends State<WrapUpPage> {
  late final TextEditingController _agreedNotesController;
  late final TextEditingController _nextTopicsController;
  List<SessionRecord> _savedRecords = const [];
  String? _statusMessage;
  bool _isBusy = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _agreedNotesController = TextEditingController(
      text: widget.draftRecord.agreedNotes,
    );
    _nextTopicsController = TextEditingController(
      text: widget.draftRecord.nextTopics,
    );
    _loadRecords();
  }

  @override
  void dispose() {
    _agreedNotesController.dispose();
    _nextTopicsController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _savedRecords = records;
    });
  }

  Future<void> _saveRecord() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    final record = widget.draftRecord.withNotes(
      agreedNotes: _agreedNotesController.text,
      nextTopics: _nextTopicsController.text,
    );
    await widget.recordStore.save(record);
    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _savedRecords = records;
      _statusMessage = '이 기기에 기록을 저장했어요.';
    });
  }

  Future<void> _deleteRecord(String id) async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    await widget.recordStore.delete(id);
    final records = await widget.recordStore.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _savedRecords = records;
      _statusMessage = '기록을 삭제했어요.';
    });
  }

  Future<void> _clearRecords() async {
    setState(() {
      _isBusy = true;
      _statusMessage = null;
    });
    await widget.recordStore.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      _savedRecords = const [];
      _statusMessage = '모든 기록을 삭제했어요.';
    });
  }

  void _finishWithoutSaving() {
    setState(() {
      _statusMessage = '기록하지 않고 마쳤어요.';
    });
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
              '대화가 끝났어요',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              '오늘의 대화를 정리해요',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('승패가 아니라, 다음 대화를 위한 기록입니다.'),
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
              agreedNotesController: _agreedNotesController,
              nextTopicsController: _nextTopicsController,
            ),
            const SizedBox(height: 14),
            CupertinoButton.filled(
              onPressed: _isBusy ? null : _saveRecord,
              child: const Text('기록 저장'),
            ),
            const SizedBox(height: 10),
            CupertinoButton(
              onPressed: _finishWithoutSaving,
              child: const Text('저장하지 않고 마치기'),
            ),
            CupertinoButton(
              onPressed: widget.onStartAnotherSession,
              child: const Text('새 대화'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              _StatusLine(_statusMessage!),
            ],
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () {
                setState(() {
                  _showHistory = !_showHistory;
                });
              },
              child: Text(_showHistory ? '저장된 기록 닫기' : '저장된 기록 보기'),
            ),
            if (_showHistory) ...[
              const SizedBox(height: 12),
              _HistorySection(
                records: _savedRecords,
                onDeleteRecord: _deleteRecord,
                onClearRecords: _savedRecords.isEmpty ? null : _clearRecords,
              ),
            ],
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
              _MetricData('종료', record.endReason.label),
              _MetricData('대화 시간', formatSeconds(record.durationSeconds)),
              _MetricData('휴식', record.breakCount.toString()),
              _MetricData('휴식 시간', formatSeconds(record.totalBreakSeconds)),
              _MetricData(
                '턴 제한',
                formatSeconds(record.config.turnLimitSeconds),
              ),
              _MetricData('알림', record.config.alertChannels),
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
            participant.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                '사용한 시간',
                formatSeconds(participant.totalUsedSeconds),
              ),
              _MetricData(
                '남은 시간',
                formatSeconds(participant.totalRemainingSeconds),
              ),
              _MetricData('차례 수', participant.turnCount.toString()),
              _MetricData(
                '오버타임 합계',
                formatSeconds(participant.overtimeTotalSeconds),
              ),
              _MetricData('주의 표시', participant.penaltyCount.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

final class _NotesSection extends StatelessWidget {
  final TextEditingController agreedNotesController;
  final TextEditingController nextTopicsController;

  const _NotesSection({
    required this.agreedNotesController,
    required this.nextTopicsController,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '메모',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('합의한 것'),
          CupertinoTextField(
            controller: agreedNotesController,
            minLines: 2,
            maxLines: 4,
            placeholder: '함께 정한 내용을 적어두세요',
          ),
          const SizedBox(height: 12),
          const _FieldLabel('다음에 이야기할 것'),
          CupertinoTextField(
            controller: nextTopicsController,
            minLines: 2,
            maxLines: 4,
            placeholder: '다음 대화로 넘길 주제를 적어두세요',
          ),
        ],
      ),
    );
  }
}

final class _HistorySection extends StatelessWidget {
  final List<SessionRecord> records;
  final ValueChanged<String> onDeleteRecord;
  final VoidCallback? onClearRecords;

  const _HistorySection({
    required this.records,
    required this.onDeleteRecord,
    required this.onClearRecords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '저장된 기록',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          const _StatusLine('저장된 기록이 아직 없어요.')
        else ...[
          ...records.map((record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SavedRecordCard(
                record: record,
                onDelete: () => onDeleteRecord(record.id),
              ),
            );
          }),
          CupertinoButton(
            color: CupertinoColors.systemRed,
            onPressed: onClearRecords,
            child: const Text('모든 기록 삭제'),
          ),
        ],
      ],
    );
  }
}

final class _SavedRecordCard extends StatelessWidget {
  final SessionRecord record;
  final VoidCallback onDelete;

  const _SavedRecordCard({required this.record, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(_formatDateTime(record.startedAt)),
          const SizedBox(height: 10),
          _MetricGrid(
            metrics: [
              _MetricData('종료', record.endReason.label),
              _MetricData(
                '턴 제한',
                formatSeconds(record.config.turnLimitSeconds),
              ),
              _MetricData(
                '주의 표시 기준',
                formatSeconds(record.config.overtimeThresholdSeconds),
              ),
              _MetricData('알림', record.config.alertChannels),
              _MetricData('휴식', record.breakCount.toString()),
            ],
          ),
          if (record.agreedNotes != null) ...[
            const SizedBox(height: 10),
            const _FieldLabel('합의한 것'),
            Text(record.agreedNotes!),
          ],
          if (record.nextTopics != null) ...[
            const SizedBox(height: 10),
            const _FieldLabel('다음에 이야기할 것'),
            Text(record.nextTopics!),
          ],
          const SizedBox(height: 12),
          CupertinoButton(
            color: CupertinoColors.systemRed,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            onPressed: onDelete,
            child: const Text('기록 삭제'),
          ),
        ],
      ),
    );
  }
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${_two(local.month)}-${_two(local.day)} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) {
  return value.toString().padLeft(2, '0');
}
