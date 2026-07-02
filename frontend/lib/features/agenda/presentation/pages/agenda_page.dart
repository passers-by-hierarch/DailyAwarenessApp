import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/agenda.dart';
import '../providers/agenda_provider.dart';

class AgendaPage extends ConsumerStatefulWidget {
  const AgendaPage({super.key});

  @override
  ConsumerState<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends ConsumerState<AgendaPage> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agendaProvider.notifier).loadTodayAgendas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendaProvider);

    final filteredAgendas = state.agendas.where((a) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'pending') return a.status == 'pending' || a.status == 'active';
      if (_selectedFilter == 'completed') return a.status == 'completed';
      if (_selectedFilter == 'skipped') return a.status == 'skipped';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('计划事程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(agendaProvider.notifier).loadTodayAgendas();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAgendaDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('全部', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('待办', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('已完成', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('已跳过', 'skipped'),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildErrorWidget(state.error!)
                    : filteredAgendas.isEmpty
                        ? _buildEmptyWidget()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredAgendas.length,
                            itemBuilder: (context, index) {
                              return _buildAgendaCard(filteredAgendas[index]);
                            },
                          ),
          ),
        ],
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
              ref.read(agendaProvider.notifier).loadTodayAgendas();
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
          Icon(Icons.calendar_today,
              size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            '暂无事程',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角按钮添加事程',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildAgendaCard(Agenda agenda) {
    final plannedTime = agenda.plannedTime;
    final isOverdue =
        plannedTime.isBefore(DateTime.now()) && agenda.status == 'pending';
    final isCompleted = agenda.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(agenda.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agenda.content,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(plannedTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (isOverdue)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '已逾期',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (agenda.behaviorTag != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.timelineType.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getBehaviorTagLabel(agenda.behaviorTag!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.timelineType,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.textSecondary),
                onSelected: (value) => _handleMenuAction(value, agenda),
                itemBuilder: (context) => [
                  if (agenda.status == 'pending') ...[
                    const PopupMenuItem(
                      value: 'confirm',
                      child: Text('确认完成'),
                    ),
                    const PopupMenuItem(
                      value: 'snooze',
                      child: Text('延后10分钟'),
                    ),
                    const PopupMenuItem(
                      value: 'skip',
                      child: Text('跳过'),
                    ),
                  ],
                  const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('删除', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, Agenda agenda) {
    switch (action) {
      case 'confirm':
        ref.read(agendaProvider.notifier).confirmAgenda(agenda.id);
        break;
      case 'snooze':
        ref.read(agendaProvider.notifier).snoozeAgenda(agenda.id, minutes: 10);
        break;
      case 'skip':
        ref.read(agendaProvider.notifier).skipAgenda(agenda.id);
        break;
      case 'delete':
        _showDeleteConfirmDialog(agenda);
        break;
    }
  }

  void _showAddAgendaDialog() {
    final contentController = TextEditingController();
    DateTime selectedTime = DateTime.now().add(const Duration(hours: 1));
    String? selectedBehaviorTag;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加事程'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '事程内容',
                  hintText: '请输入事程内容',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('计划时间'),
                subtitle: Text(
                    '${selectedTime.year}-${selectedTime.month.toString().padLeft(2, '0')}-${selectedTime.day.toString().padLeft(2, '0')} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final ctx = context;
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: selectedTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(selectedTime),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
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
                ref.read(agendaProvider.notifier).createAgenda(
                      plannedTime: selectedTime,
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

  void _showDeleteConfirmDialog(Agenda agenda) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个事程吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              await ref.read(agendaProvider.notifier).deleteAgenda(agenda.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
      case 'active':
        return AppColors.warning;
      case 'completed':
      case 'matched':
        return AppColors.success;
      case 'skipped':
        return AppColors.textSecondary;
      case 'snoozed':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '今天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (time.year == tomorrow.year &&
        time.month == tomorrow.month &&
        time.day == tomorrow.day) {
      return '明天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
