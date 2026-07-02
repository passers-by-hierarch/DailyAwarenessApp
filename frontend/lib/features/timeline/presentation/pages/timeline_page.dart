import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/timeline_record.dart';
import '../providers/timeline_provider.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timelineProvider.notifier).loadTodayTimeline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('时间线'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(timelineProvider.notifier).loadTodayTimeline();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildErrorWidget(state.error!)
              : state.records.isEmpty
                  ? _buildEmptyWidget()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.records.length,
                      itemBuilder: (context, index) {
                        final record = state.records[index];
                        return _buildTimelineItem(record);
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            '加载失败：$error',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(timelineProvider.notifier).loadTodayTimeline();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            '暂无记录',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右下角按钮添加记录',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineRecord record) {
    final isMatched = record.matchedAgendaId != null;
    final timestamp = record.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${timestamp.month}/${timestamp.day}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.content,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getSourceColor(record.source).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getSourceLabel(record.source),
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSourceColor(record.source),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (record.behaviorTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.timelineType.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getBehaviorTagLabel(record.behaviorTag!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.timelineType,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (isMatched) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '已匹配',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) => _handleMenuAction(value, record),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('编辑'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, TimelineRecord record) {
    switch (action) {
      case 'edit':
        _showEditDialog(record);
        break;
      case 'delete':
        _showDeleteConfirmDialog(record);
        break;
    }
  }

  void _showAddRecordDialog() {
    final contentController = TextEditingController();
    String? selectedBehaviorTag;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '记录内容',
                  hintText: '请输入记录内容',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBehaviorTag,
                decoration: const InputDecoration(
                  labelText: '行为标签（可选）',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('无')),
                  DropdownMenuItem(value: 'eating', child: Text('用餐')),
                  DropdownMenuItem(value: 'sleeping', child: Text('睡眠')),
                  DropdownMenuItem(value: 'exercising', child: Text('运动')),
                  DropdownMenuItem(value: 'medication', child: Text('服药')),
                  DropdownMenuItem(value: 'reading', child: Text('阅读')),
                  DropdownMenuItem(value: 'housework', child: Text('家务')),
                  DropdownMenuItem(value: 'social', child: Text('社交')),
                ],
                onChanged: (value) {
                  setState(() => selectedBehaviorTag = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) return;
                ref.read(timelineProvider.notifier).createTimeline(
                      timestamp: DateTime.now(),
                      content: contentController.text.trim(),
                      behaviorTag: selectedBehaviorTag,
                    );
                Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(TimelineRecord record) {
    final contentController = TextEditingController(text: record.content);
    String? selectedBehaviorTag = record.behaviorTag;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑记录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '记录内容',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBehaviorTag,
                decoration: const InputDecoration(
                  labelText: '行为标签',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('无')),
                  DropdownMenuItem(value: 'eating', child: Text('用餐')),
                  DropdownMenuItem(value: 'sleeping', child: Text('睡眠')),
                  DropdownMenuItem(value: 'exercising', child: Text('运动')),
                  DropdownMenuItem(value: 'medication', child: Text('服药')),
                  DropdownMenuItem(value: 'reading', child: Text('阅读')),
                  DropdownMenuItem(value: 'housework', child: Text('家务')),
                  DropdownMenuItem(value: 'social', child: Text('社交')),
                ],
                onChanged: (value) {
                  setState(() => selectedBehaviorTag = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.trim().isEmpty) return;
                ref.read(timelineProvider.notifier).updateTimeline(
                      id: record.id,
                      content: contentController.text.trim(),
                      behaviorTag: selectedBehaviorTag,
                    );
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(TimelineRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              ref.read(timelineProvider.notifier).deleteTimeline(record.id);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'voice':
        return AppColors.primary;
      case 'manual':
        return AppColors.timelineType;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'voice':
        return '语音';
      case 'manual':
        return '手动';
      default:
        return '记录';
    }
  }

  String _getBehaviorTagLabel(String tag) {
    const labels = {
      'eating': '用餐',
      'sleeping': '睡眠',
      'exercising': '运动',
      'medication': '服药',
      'reading': '阅读',
      'watching_tv': '看电视',
      'housework': '家务',
      'social': '社交',
      'hygiene': '洗漱',
      'shopping': '购物',
      'outdoor': '外出',
      'rest': '休息',
    };
    return labels[tag] ?? tag;
  }
}
