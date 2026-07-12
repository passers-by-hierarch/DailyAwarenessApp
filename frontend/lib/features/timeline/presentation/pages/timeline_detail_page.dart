import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../../layouts/secondary_layout.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/state/app_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../shared/widgets/new_tag_dialog.dart';
import '../../../../shared/widgets/smart_recognition_card.dart';

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
          // 显示智能识别结果卡片
          if (record.sideEffects?.intentData != null) ...[
            const SizedBox(height: 12),
            SmartRecognitionCard(record: record),
          ],
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧类型图标
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeBadge.$2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(typeBadge.$4, size: 22, color: typeBadge.$3),
            ),
          ),
          const SizedBox(width: 12),
          // 右侧内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      record.timeStr,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeBadge.$2,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeBadge.$1,
                        style: TextStyle(fontSize: 12, color: typeBadge.$3, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  record.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 返回 (标签文字, 背景色, 文字色, 图标)
  (String, Color, Color, IconData) _typeBadge(TimelineType type) {
    switch (type) {
      case TimelineType.behavior:
        return ('行为活动', AppColors.accentLight, AppColors.accent, AppIcons.activity);
      case TimelineType.item:
        return ('物品位置', AppColors.infoLight, AppColors.info, AppIcons.package);
      case TimelineType.shopping:
        return ('购物记录', AppColors.warningLight, AppColors.warning, AppIcons.shoppingCart);
      case TimelineType.event:
        return ('日常事件', AppColors.successLight, AppColors.success, AppIcons.mapPin);
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
              const Text('智能标签', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showTagEditor(record),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.tag, size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    const Text('修改标签', style: TextStyle(fontSize: 13, color: AppColors.accent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: record.tags.map((tid) {
              final def = allTags.where((t) => t.id == tid).firstOrNull;
              if (def == null) {
                return _tagChip(tid, null, AppColors.textSecondary, AppColors.bgTertiary);
              }
              final colorSet = AppColors.tagColors[def.color] ?? AppColors.tagColors['gray']!;
              final icon = _resolveTagIcon(def);
              return _tagChip(def.name, icon, colorSet.color, colorSet.bg);
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            '标签不准？点击"修改标签"调整，系统会记住你的偏好',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, IconData? icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
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
          Text(record.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
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
            Text(note.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
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

  static const Map<String, IconData> _iconMap = {
    'hash': LucideIcons.hash,
    'tag': LucideIcons.tag,
    'activity': LucideIcons.activity,
    'package': LucideIcons.package,
    'shopping_cart': LucideIcons.shopping_cart,
    'map_pin': LucideIcons.map_pin,
    'heart': LucideIcons.heart,
    'star': LucideIcons.star,
    'clock': LucideIcons.clock,
    'book': LucideIcons.book_open,
    'music': LucideIcons.music,
    'camera': LucideIcons.camera,
    'lightbulb': LucideIcons.lightbulb,
    'target': LucideIcons.target,
    'award': LucideIcons.award,
    'user': LucideIcons.user,
    'home': LucideIcons.house,
    'settings': LucideIcons.settings,
    'smile': LucideIcons.smile,
    'coffee': LucideIcons.coffee,
    'utensils': LucideIcons.utensils,
    'dumbbell': LucideIcons.dumbbell,
    'pill': LucideIcons.pill,
    'droplet': LucideIcons.droplet,
  };

  IconData _resolveTagIcon(TagDef tag) {
    return _iconMap[tag.icon] ?? LucideIcons.hash;
  }

  void _showTagEditor(TimelineRecord record) {
    final store = context.read<AppStore>();
    final selected = List<String>.from(record.tags);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: AppColors.bgSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                  child: Row(
                    children: [
                      const Icon(AppIcons.tag, size: 20, color: AppColors.accent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '修改标签',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.bgTertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(AppIcons.x, size: 18, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                // 副标题
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '选择合适的标签，系统会记住你的偏好，下次同类话语自动应用',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(height: 16),
                // 标签列表
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 系统标签
                        _buildTagSection(
                          title: '系统标签',
                          tags: TagDef.systemTags,
                          selected: selected,
                          dialogContext: ctx,
                          onToggle: (tagId) => setSt(() {
                            if (selected.contains(tagId)) {
                              selected.remove(tagId);
                            } else {
                              selected.add(tagId);
                            }
                          }),
                        ),
                        const SizedBox(height: 16),
                        // 我的标签
                        _buildTagSection(
                          title: '我的标签',
                          tags: store.customTags,
                          selected: selected,
                          dialogContext: ctx,
                          onToggle: (tagId) => setSt(() {
                            if (selected.contains(tagId)) {
                              selected.remove(tagId);
                            } else {
                              selected.add(tagId);
                            }
                          }),
                        ),
                        const SizedBox(height: 12),
                        // 新建标签按钮
                        GestureDetector(
                          onTap: () async {
                            final result = await showDialog(
                              context: ctx,
                              builder: (dialogCtx) => const NewTagDialog(),
                            );
                            if (result != null && result is Map<String, dynamic>) {
                              final addResult = store.addCustomTag(
                                name: result['name'] as String,
                                color: result['color'] as String,
                                icon: result['icon'] as String,
                              );
                              if (addResult['success'] == true) {
                                final newTagId = store.customTags.last.id;
                                setSt(() {
                                  selected.add(newTagId);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('标签创建成功'), duration: Duration(seconds: 1)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(addResult['error'] ?? '创建失败'), duration: Duration(seconds: 1)),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border, width: 1, style: BorderStyle.solid),
                            ),
                            child: Row(
                              children: const [
                                Icon(AppIcons.plusCircle, size: 18, color: AppColors.textSecondary),
                                SizedBox(width: 12),
                                Text(
                                  '新建标签',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // 底部按钮
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('取消', style: TextStyle(color: AppColors.textTertiary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<AppStore>().updateRecordTags(record.id, selected);
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            '保存',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSection({
    required String title,
    required List<TagDef> tags,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    required BuildContext dialogContext,
  }) {
    final store = context.read<AppStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        ...tags.map((tag) {
          final isSelected = selected.contains(tag.id);
          final colorSet = AppColors.tagColors[tag.color] ?? AppColors.tagColors['gray']!;
          final icon = _resolveTagIcon(tag);
          final isCustom = !tag.system;

          return GestureDetector(
            onTap: () => onToggle(tag.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? colorSet.bg : AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? colorSet.color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colorSet.color.withOpacity(isSelected ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(icon, size: 16, color: colorSet.color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 名称
                  Expanded(
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? colorSet.color : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // 自定义标签：编辑+删除按钮
                  if (isCustom) ...[
                    GestureDetector(
                      onTap: () async {
                        final result = await showDialog(
                          context: dialogContext,
                          builder: (dialogCtx) => NewTagDialog(
                            initialName: tag.name,
                            initialColor: tag.color,
                            initialIcon: tag.icon,
                            isEdit: true,
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          final editResult = store.editCustomTag(
                            tag.id,
                            name: result['name'] as String,
                            color: result['color'] as String,
                            icon: result['icon'] as String,
                          );
                          if (editResult['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('标签已更新'), duration: Duration(seconds: 1)),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(editResult['error'] ?? '更新失败'), duration: Duration(seconds: 1)),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(AppIcons.edit2, size: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: dialogContext,
                          builder: (dialogCtx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除标签"${tag.name}"吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: const Text('取消'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: () {
                                  store.deleteCustomTag(tag.id);
                                  Navigator.pop(dialogCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('标签已删除'), duration: Duration(seconds: 1)),
                                  );
                                },
                                child: const Text('删除', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgTertiary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(AppIcons.trash2, size: 14, color: AppColors.danger),
                      ),
                    ),
                  ],
                  // 勾选标记
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorSet.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Icon(AppIcons.check, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
