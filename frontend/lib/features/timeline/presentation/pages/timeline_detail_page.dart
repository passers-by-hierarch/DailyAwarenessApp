import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';

/// 时间线记录详情页 - 对齐原型 TimelineDetailPage
class TimelineDetailPage extends StatefulWidget {
  const TimelineDetailPage({super.key});

  @override
  State<TimelineDetailPage> createState() => _TimelineDetailPageState();
}

class _TimelineDetailPageState extends State<TimelineDetailPage> {
  bool _recording = false;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final recordId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final record = context.select<AppStore, TimelineRecord?>(
      (s) => s.timelineRecords.where((r) => r.id == recordId).firstOrNull,
    );

    if (record == null) {
      return const SecondaryScaffold(
        title: '记录详情',
        body: Center(child: Text('记录不存在', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return SecondaryScaffold(
      title: '记录详情',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(record),
          const SizedBox(height: 12),
          _buildTagsSection(record),
          const SizedBox(height: 12),
          _buildVoiceCard(record),
          const SizedBox(height: 12),
          _buildNotesSection(record),
          const SizedBox(height: 12),
          _buildExtractionSection(record),
          if (record.matchedAgenda != null) ...[
            const SizedBox(height: 12),
            _buildMatchedAgendaCard(record.matchedAgenda!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(TimelineRecord record) {
    final typeBadge = _typeBadge(record.type);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(record.timeStr,
                  style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(record.date, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeBadge.$2, borderRadius: BorderRadius.circular(6)),
                child: Text(typeBadge.$1, style: TextStyle(fontSize: 12, color: typeBadge.$3, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(record.content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  (String, Color, Color) _typeBadge(TimelineType type) {
    switch (type) {
      case TimelineType.behavior:
        return ('行为', AppColors.accentLight, AppColors.accent);
      case TimelineType.item:
        return ('物品', AppColors.infoLight, AppColors.info);
      case TimelineType.shopping:
        return ('购物', AppColors.warningLight, AppColors.warning);
      case TimelineType.event:
        return ('事件', AppColors.successLight, AppColors.success);
    }
  }

  Widget _buildTagsSection(TimelineRecord record) {
    final store = context.read<AppStore>();
    final allTags = store.allTags;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('智能标签', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showTagEditor(record),
                child: const Text('编辑', style: TextStyle(fontSize: 13, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: record.tags.map((tid) {
              final def = allTags.where((t) => t.id == tid).firstOrNull;
              if (def == null) {
                return _tagChip(tid, AppColors.textSecondary, AppColors.bgTertiary);
              }
              final colorSet = AppColors.tagColors[def.color] ?? AppColors.tagColors['gray']!;
              return _tagChip(def.name, colorSet.color, colorSet.bg);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildVoiceCard(TimelineRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('原始语音内容', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _isPlaying = !_isPlaying);
              if (_isPlaying) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('正在播放语音'), duration: Duration(seconds: 2)),
                );
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _isPlaying = false);
                });
              }
            },
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isPlaying ? AppColors.danger : AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_isPlaying ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      24,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 2),
                        width: 3,
                        height: _isPlaying ? 8 + ((i + DateTime.now().millisecond ~/ 100) % 5) * 4.0 : 8 + (i % 5) * 4.0,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(_isPlaying ? 0.6 + ((i + DateTime.now().millisecond ~/ 100) % 4) * 0.1 : 0.4 + (i % 4) * 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('0:08', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(record.content, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildNotesSection(TimelineRecord record) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('补充记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          // 输入区域
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: '输入补充内容...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (text) => _submitTextNote(record.id),
                  ),
                ),
                const SizedBox(width: 8),
                // 语音输入按钮
                GestureDetector(
                  onTap: _startVoiceNote,
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _recording ? AppColors.danger : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_recording ? Icons.stop : Icons.mic, color: Colors.white, size: 18),
                  ),
                ),
                // 发送按钮
                GestureDetector(
                  onTap: () => _submitTextNote(record.id),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...record.notes.map((n) => _buildNoteItem(record.id, n)),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String recordId, NoteEntry note) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在播放语音'), duration: Duration(seconds: 2)),
        );
      },
      onLongPress: () {
        context.read<AppStore>().deleteNoteFromRecord(recordId, note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除补充记录'), duration: Duration(seconds: 1)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.graphic_eq, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  '${note.time.hour.toString().padLeft(2, '0')}:${note.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(note.content, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _submitTextNote(String recordId) {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    context.read<AppStore>().addNoteToRecord(recordId, text);
    _noteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加补充记录'), duration: Duration(seconds: 1)),
    );
  }

  void _startVoiceNote() {
    final recordId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    if (_recording) {
      setState(() => _recording = false);
      // 模拟语音识别转文字，实际应调用语音识别服务
      final recognizedText = _simulateVoiceRecognition();
      context.read<AppStore>().addNoteToRecord(recordId, recognizedText);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已添加语音补充记录'), duration: Duration(seconds: 1)),
      );
    } else {
      setState(() => _recording = true);
    }
  }

  String _simulateVoiceRecognition() {
    // 模拟语音识别结果。实际项目中应调用 Speech-to-Text 服务
    final samples = [
      '我已经吃完药了，感觉还不错',
      '我刚散完步回来，走了大概30分钟',
      '我现在准备喝水',
      '我已经完成今天的运动了',
    ];
    return samples[DateTime.now().millisecond % samples.length];
  }

  Widget _buildExtractionSection(TimelineRecord record) {
    final sideEffects = record.sideEffects;
    if (sideEffects == null) return const SizedBox.shrink();

    final List<Widget> extracts = [];
    if (sideEffects.shoppingRecord != null) {
      final sr = sideEffects.shoppingRecord!;
      extracts.add(_extractItem('商店', sr.store));
      extracts.add(_extractItem('商品数', '${sr.items.length} 件'));
      for (final it in sr.items) {
        extracts.add(_extractItem(it.name, '${it.quantity} ${it.unit}'));
      }
    }
    if (sideEffects.itemUpdate != null) {
      extracts.add(_extractItem('物品', sideEffects.itemUpdate!.name));
      extracts.add(_extractItem('位置', sideEffects.itemUpdate!.location));
    }

    if (extracts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('智能识别结果', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ...extracts,
        ],
      ),
    );
  }

  Widget _extractItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(4)),
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildMatchedAgendaCard(String matchedAgenda) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          const Text('关联事程', style: TextStyle(fontSize: 14, color: AppColors.success, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(matchedAgenda, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showTagEditor(TimelineRecord record) {
    final store = context.read<AppStore>();
    final allTags = store.allTags;
    final selected = List<String>.from(record.tags);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('编辑标签'),
          content: SizedBox(
            width: double.maxFinite,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: allTags.map((t) {
                final isSelected = selected.contains(t.id);
                final colorSet = AppColors.tagColors[t.color] ?? AppColors.tagColors['gray']!;
                return FilterChip(
                  label: Text(t.name),
                  selected: isSelected,
                  onSelected: (v) => setSt(() {
                    if (v) {
                      selected.add(t.id);
                    } else {
                      selected.remove(t.id);
                    }
                  }),
                  backgroundColor: colorSet.bg,
                  selectedColor: colorSet.bg,
                  labelStyle: TextStyle(
                    color: isSelected ? colorSet.color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(color: isSelected ? colorSet.color : AppColors.border),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                context.read<AppStore>().updateRecordTags(record.id, selected);
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
