import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/state/app_store.dart';
import '../../../../shared/widgets/timeline_item.dart';
import '../../../../shared/widgets/agenda_item.dart';
import '../../../../shared/widgets/swipe_delete_wrapper.dart';

/// 首页 - 对齐 HomePage.tsx
/// 时间线/事程双 Tab + 日历弹窗 + 问候语 + 到时提醒
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _activeTab = 'timeline';
  bool _showCalendar = false;
  bool _showCreateModal = false;
  late String _selectedDateKey;
  late int _calYear;
  late int _calMonth;
  Timer? _reminderTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDateKey = _ymd(now);
    _calYear = now.year;
    _calMonth = now.month - 1;
    // 启动提醒检查
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkReminders();
    });
    // 每分钟检查事程提醒
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _checkReminders();
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _checkReminders() {
    final store = context.read<AppStore>();
    store.checkAgendaReminders();
  }

  String _selectedDateStr() {
    final parts = _selectedDateKey.split('-');
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    final prefix = _isToday ? '今天 ' : '';
    return '$prefix${int.parse(parts[1])}月${int.parse(parts[2])}日 ${weekdays[dt.weekday % 7]}';
  }

  bool get _isToday => _selectedDateKey == _ymd(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final todayStr = _ymd(DateTime.now());

    final dayTimeline = store.timelineRecords.where((r) => r.date == _selectedDateKey).toList();
    final dayAgendas = store.agendaItems.where((a) => a.date == _selectedDateKey).toList();

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    AgendaStatus effectiveStatus(AgendaItem a) {
      if (a.status == AgendaStatus.pending && _isToday) {
        final parts = a.time.split(':');
        final m = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
        if (m < nowMinutes) return AgendaStatus.expired;
      }
      return a.status;
    }

    final pending = dayAgendas.where((a) => effectiveStatus(a) == AgendaStatus.pending)
        .toList()..sort((a, b) => a.time.compareTo(b.time));
    final expired = dayAgendas.where((a) => effectiveStatus(a) == AgendaStatus.expired)
        .toList()..sort((a, b) => b.time.compareTo(a.time));
    final completed = dayAgendas.where((a) => a.status == AgendaStatus.completed).toList();

    final pendingCount = pending.length;
    final completedCount = completed.length;
    final totalCount = dayAgendas.length;

    return Container(
      color: AppColors.bgPrimary,
      child: Stack(
        children: [
          Column(
            children: [
              // 顶部信息区 - 对齐设计文档 2.3.1
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.bgPrimary,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _showCalendar = true);
                        context.read<AppStore>().setHomeOverlayOpen(true);
                      },
                      child: Row(
                        children: [
                          Text(
                            _selectedDateStr(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                    if (_isToday)
                      Text(
                        totalCount > 0 ? '今日 $completedCount/$totalCount' : '今日',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => setState(() => _selectedDateKey = todayStr),
                        child: const Text(
                          '回到今天',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.accent),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isToday)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${store.greeting}，今天已完成$completedCount项事程',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              // Tab 切换区 - 对齐设计文档 2.3.2：活跃标签用绿色胶囊样式
              // Tab切换区 - 横框内分成两部分，各占50%
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.bgPrimary,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          '时间线',
                          '${dayTimeline.length}',
                          dayTimeline.length,
                          _activeTab == 'timeline',
                          () => setState(() => _activeTab = 'timeline'),
                        ),
                      ),
                      Expanded(
                        child: _buildTabButton(
                          '事程',
                          '$pendingCount/$totalCount',
                          totalCount,
                          _activeTab == 'agenda',
                          () => setState(() => _activeTab = 'agenda'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 内容区
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _activeTab == 'timeline'
                      ? _buildTimelineContent(dayTimeline)
                      : _buildAgendaContent(pending, expired, completed, dayAgendas),
                ),
              ),
            ],
          ),
          // 弹窗层
          if (store.activeReminder != null)
            _buildReminderDialog(store),
          if (_showCalendar)
            _buildCalendarDialog(store),
          if (_showCreateModal)
            _buildCreateAgendaDialog(store),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String countLabel, int count, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: 44,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(9999), // 胶囊形
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.25) : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    countLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineContent(List<TimelineRecord> records) {
    if (records.isEmpty) {
      return [
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              const Text('📭', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                _isToday ? '点击下方语音按钮开始记录' : '该日无时间线记录',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ];
    }
    return records.map((r) => SwipeDeleteWrapper(
      onDelete: () => context.read<AppStore>().deleteTimelineRecord(r.id),
      confirmText: '删除',
      child: TimelineItemWidget(
        record: r,
        onTap: () => Navigator.pushNamed(context, '/timeline', arguments: r.id),
      ),
    )).toList();
  }

  List<Widget> _buildAgendaContent(List<AgendaItem> pending, List<AgendaItem> expired, List<AgendaItem> completed, List<AgendaItem> all) {
    final widgets = <Widget>[];
    final store = context.read<AppStore>();

    // 待确认事程（时间推断 UI）
    if (_isToday && store.pendingAgendaConfirm.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: _buildPendingAgendaCard(store),
      ));
    }

    if (_isToday) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GestureDetector(
          onTap: () {
            setState(() => _showCreateModal = true);
            context.read<AppStore>().setHomeOverlayOpen(true);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 16, color: AppColors.accent),
                SizedBox(width: 6),
                Text('添加新事程', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.accent)),
              ],
            ),
          ),
        ),
      ));
    }

    // 事程冲突警告
    final conflictWarning = store.agendaConflictWarning;
    if (conflictWarning != null) {
      final newAgenda = conflictWarning['newAgenda'] as AgendaItem;
      final conflicts = conflictWarning['conflicts'] as List<AgendaItem>;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('事程时间冲突', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 8),
              Text('您添加的"${newAgenda.content}"与以下事程时间相同：', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              ...conflicts.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('• ${c.time} ${c.content}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              )),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('💡 建议：调整其中一个的时间', style: TextStyle(fontSize: 12, color: Colors.orange)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => store.clearAgendaConflictWarning(),
                    child: const Text('关闭', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
    }

    if (all.isEmpty) {
      widgets.add(const SizedBox(height: 32));
      widgets.add(Center(
        child: Column(
          children: [
            const Text('📭', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              _isToday ? '暂无今日事程' : '该日无事程记录',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ));
      return widgets;
    }

    if (pending.isNotEmpty) {
      widgets.add(Container(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('待进行 (${pending.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
      ));
      widgets.addAll(pending.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: SwipeDeleteWrapper(
          onDelete: () => _showDeleteConfirmDialog(a),
          confirmText: '删除',
          child: AgendaItemWidget(
            item: a,
            onTap: () => Navigator.pushNamed(context, '/agenda', arguments: a.id),
            onComplete: () => context.read<AppStore>().completeAgenda(a.id),
            onPostpone: () => _showPostponeDialog(a.id),
          ),
        ),
      )));
    }

    if (expired.isNotEmpty) {
      widgets.add(Container(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('已过期 (${expired.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
      ));
      widgets.addAll(expired.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: SwipeDeleteWrapper(
          onDelete: () => _showDeleteConfirmDialog(a),
          confirmText: '删除',
          child: AgendaItemWidget(
            item: a,
            onTap: () => Navigator.pushNamed(context, '/agenda', arguments: a.id),
          ),
        ),
      )));
    }

    if (completed.isNotEmpty) {
      widgets.add(Container(
        padding: const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('已完成 (${completed.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
      ));
      widgets.addAll(completed.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: SwipeDeleteWrapper(
          onDelete: () => context.read<AppStore>().deleteAgenda(a.id),
          confirmText: '删除',
          child: AgendaItemWidget(
            item: a,
            onTap: () => Navigator.pushNamed(context, '/agenda', arguments: a.id),
          ),
        ),
      )));
    }

    return widgets;
  }

  Widget _buildPendingAgendaCard(AppStore store) {
    final pendings = store.pendingAgendaConfirm;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                const Text('待确认事程',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning)),
                const Spacer(),
                GestureDetector(
                  onTap: () => store.clearPendingAgenda(),
                  child: const Text('全部忽略',
                      style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ),
              ],
            ),
          ),
          ...pendings.map((p) => _buildPendingItem(store, p)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPendingItem(AppStore store, PendingAgendaItem item) {
    final sourceLabel = item.timeSource == TimeSource.history
        ? '基于历史习惯'
        : item.timeSource == TimeSource.commonSense
            ? '基于常识推断'
            : item.timeSource == TimeSource.userSpecified
                ? '用户指定时间'
                : '当前时间';

    final sourceColor = item.timeSource == TimeSource.history
        ? AppColors.accent
        : item.timeSource == TimeSource.commonSense
            ? AppColors.info
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.content,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ),
              // 时间调整
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final newTime = _adjustTime(item.suggestedTime, -15);
                      store.updatePendingAgendaTime(item.id, newTime);
                    },
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(item.suggestedTime,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () {
                      final newTime = _adjustTime(item.suggestedTime, 15);
                      store.updatePendingAgendaTime(item.id, newTime);
                    },
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sourceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(sourceLabel,
                    style: TextStyle(fontSize: 10, color: sourceColor)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  store.rejectPendingAgenda([item.id]);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('取消',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  store.confirmPendingAgenda([item.id]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加到今日事程'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('确认',
                      style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _adjustTime(String time, int minutesDelta) {
    final parts = time.split(':');
    if (parts.length != 2) return time;
    int h = int.tryParse(parts[0]) ?? 0;
    int m = int.tryParse(parts[1]) ?? 0;
    int total = h * 60 + m + minutesDelta;
    if (total < 0) total = 0;
    if (total >= 24 * 60) total = 24 * 60 - 1;
    final nh = total ~/ 60;
    final nm = total % 60;
    return '${nh.toString().padLeft(2, '0')}:${nm.toString().padLeft(2, '0')}';
  }

  void _showPostponeDialog(String agendaId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('推迟事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [5, 10, 15, 30].map((m) => ElevatedButton(
                onPressed: () {
                  context.read<AppStore>().postponeAgenda(agendaId, m);
                  Navigator.pop(ctx);
                },
                child: Text('$m 分钟'),
              )).toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(AgendaItem agenda) {
    if (!agenda.isHighFrequency && !agenda.isMustDo) {
      context.read<AppStore>().deleteAgenda(agenda.id);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('删除事程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              agenda.isHighFrequency ? '这是高频事程，删除后还会自动添加到每日事程中，是否要彻底停止自动添加？' : '这是必做事程，确定要删除吗？',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgTertiary, foregroundColor: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgTertiary, foregroundColor: AppColors.textSecondary),
                    onPressed: () {
                      context.read<AppStore>().deleteAgenda(agenda.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text('仅删今天'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<AppStore>().deleteAgendaWithOption(agenda.id, true);
                      Navigator.pop(ctx);
                    },
                    child: const Text('不再自动添加'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderDialog(AppStore store) {
    return _ReminderDialog(reminder: store.activeReminder!, store: store);
  }

  Widget _buildCalendarDialog(AppStore store) {
    final todayStr = _ymd(DateTime.now());
    final datesWithRecords = <String>{};
    for (final r in store.timelineRecords) datesWithRecords.add(r.date);
    for (final a in store.agendaItems) datesWithRecords.add(a.date);

    final firstDay = DateTime(_calYear, _calMonth + 1, 1);
    final lastDay = DateTime(_calYear, _calMonth + 2, 0);
    final startWeekday = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;

    final cells = <int?>[];
    for (int i = 0; i < startWeekday; i++) cells.add(null);
    for (int d = 1; d <= daysInMonth; d++) cells.add(d);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _showCalendar = false);
            context.read<AppStore>().setHomeOverlayOpen(false);
          },
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          if (_calMonth == 0) { _calYear--; _calMonth = 11; } else { _calMonth--; }
                        }),
                        child: const SizedBox(width: 32, height: 32, child: Icon(Icons.chevron_left, size: 18, color: AppColors.textSecondary)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text('$_calYear年${_calMonth + 1}月', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          if (_calMonth == 11) { _calYear++; _calMonth = 0; } else { _calMonth++; }
                        }),
                        child: const SizedBox(width: 32, height: 32, child: Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: ['日', '一', '二', '三', '四', '五', '六'].map((w) =>
                      Expanded(child: Center(child: Text(w, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary))))
                    ).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
                    itemCount: cells.length,
                    itemBuilder: (ctx, i) {
                      final day = cells[i];
                      if (day == null) return const SizedBox();
                      final dateKey = _ymd(DateTime(_calYear, _calMonth + 1, day));
                      final isSelected = _selectedDateKey == dateKey;
                      final isTodayCell = todayStr == dateKey;
                      final hasRecord = datesWithRecords.contains(dateKey);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDateKey = dateKey;
                            _showCalendar = false;
                          });
                          context.read<AppStore>().setHomeOverlayOpen(false);
                        },
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accentLight : null,
                              shape: BoxShape.circle,
                              border: isTodayCell && !isSelected ? Border.all(color: AppColors.accent) : null,
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected || isTodayCell ? FontWeight.w600 : hasRecord ? FontWeight.w500 : FontWeight.w400,
                                  color: isSelected ? AppColors.accent : isTodayCell ? AppColors.accent : hasRecord ? AppColors.textPrimary : AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAgendaDialog(AppStore store) {
    return StatefulBuilder(
      builder: (ctx, setState) => CreateAgendaModal(
        onClose: () {
          setState(() => _showCreateModal = false);
          context.read<AppStore>().setHomeOverlayOpen(false);
        },
      ),
    );
  }
}

class _ReminderDialog extends StatefulWidget {
  final AgendaItem reminder;
  final AppStore store;
  const _ReminderDialog({required this.reminder, required this.store});

  @override
  State<_ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<_ReminderDialog> {
  bool _isRecording = false;
  String _recordText = '';
  int _recordSeconds = 0;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  bool _isCompleted = false;
  String _analysisResult = '';

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _recordText = '';
    });
    _startTimer();
  }

  void _startTimer() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 60) {
        _stopRecording();
      }
    }
  }

  void _stopRecording() {
    if (!_isRecording) return;
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
      _recordText = '我已经吃完药了';
    });
    _analyzeRecording();
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
      _recordText = '';
    });
  }

  void _analyzeRecording() async {
    setState(() => _isAnalyzing = true);

    final reminder = widget.reminder;
    final agendaContent = reminder.content;
    final recordText = _recordText;

    // 1. 先判断语义相关性：语音内容是否与事程内容相关
    final isRelevant = _isContentRelevant(agendaContent, recordText);

    // 2. 判断用户是否表达"已完成"
    final hasCompletedIntent = _detectCompletionIntent(recordText);
    final hasPendingIntent = _detectPendingIntent(recordText);

    // 3. 结合事程时间判断
    final now = DateTime.now();
    final parts = reminder.time.split(':');
    final agendaHour = int.tryParse(parts[0]) ?? now.hour;
    final agendaMinute = int.tryParse(parts[1]) ?? now.minute;
    final agendaDateTime = DateTime(now.year, now.month, now.day, agendaHour, agendaMinute);
    final isPast = agendaDateTime.isBefore(now);

    bool shouldComplete = false;
    String resultText = '';

    if (!isRelevant) {
      // 语音内容与事程无关
      shouldComplete = false;
      resultText = 'AI判断：内容与"$agendaContent"不匹配，未判定完成';
    } else if (hasPendingIntent) {
      // 用户明确表达未完成/待完成
      shouldComplete = false;
      resultText = 'AI判断：待进行';
    } else if (hasCompletedIntent) {
      // 用户表达已完成
      shouldComplete = true;
      resultText = 'AI判断：已完成';
    } else {
      // 无法明确判断，根据时间给出默认结论
      if (isPast) {
        shouldComplete = false;
        resultText = 'AI判断：待进行（请确认是否已完成）';
      } else {
        shouldComplete = false;
        resultText = 'AI判断：待进行';
      }
    }

    setState(() {
      _isCompleted = shouldComplete;
      _analysisResult = resultText;
    });

    if (shouldComplete) {
      widget.store.completeAgenda(widget.reminder.id);
      widget.store.addTimelineRecord(TimelineRecord(
        id: '',
        content: recordText,
        time: DateTime.now(),
        matchedAgenda: '${reminder.time} ${reminder.content}',
      ));
    }

    setState(() {
      _isAnalyzing = false;
      _analysisComplete = true;
    });
  }

  /// 判断语音内容是否与事程内容语义相关
  bool _isContentRelevant(String agendaContent, String userText) {
    final agenda = agendaContent.toLowerCase();
    final text = userText.toLowerCase();

    // 提取事程关键词
    final agendaKeywords = _extractKeywords(agenda);
    final userKeywords = _extractKeywords(text);

    // 有直接包含关系
    if (agendaKeywords.any((k) => text.contains(k))) return true;
    if (userKeywords.any((k) => agenda.contains(k))) return true;

    // 同义词/近义词匹配
    final synonymMap = {
      '药': ['吃药', '服药', '吃药片', '喝水', '喝药'],
      '运动': ['散步', '跑步', '锻炼', '走路', '健身'],
      '吃饭': ['吃', '用餐', '午饭', '晚饭', '早餐'],
      '睡觉': ['睡', '休息', '躺下', '上床'],
      '洗漱': ['洗脸', '刷牙', '洗澡', '洗手'],
      '喝水': ['喝', '饮水', '水杯'],
    };

    for (final entry in synonymMap.entries) {
      final key = entry.key;
      final synonyms = entry.value;
      final isAgendaRelated = agenda.contains(key) || synonyms.any((s) => agenda.contains(s));
      final isUserRelated = text.contains(key) || synonyms.any((s) => text.contains(s));
      if (isAgendaRelated && isUserRelated) return true;
    }

    // 如果用户说"完成"了，且事程是常见行为，也视为相关
    if (text.contains('完成') && agendaKeywords.any((k) => ['药', '运动', '饭', '吃', '睡', '洗', '水'].any((c) => k.contains(c)))) {
      return true;
    }

    return false;
  }

  List<String> _extractKeywords(String text) {
    // 简单关键词提取：过滤停用词，保留名词性内容
    final stopWords = {'了', '的', '我', '在', '是', '和', '就', '都', '要', '会', '能', '可以', '把', '到', '上', '下', '过', '完', '着', '一', '个', '今天', '现在', '准备', '刚刚'};
    final chars = <String>[];
    for (final word in text.split('')) {
      if (!stopWords.contains(word) && word.trim().isNotEmpty) {
        chars.add(word);
      }
    }
    return chars;
  }

  /// 检测用户是否表达"已完成"
  bool _detectCompletionIntent(String text) {
    final lower = text.toLowerCase();
    final completedKeywords = [
      '完成', '做完了', '吃完了', '吃完了', '吃过了', '已经吃了', '已经做了',
      '好了', '搞定了', '做完了', '散完步了', '吃好了', '喝完了', '吃完了',
      '我刚吃完', '我刚做完', '我刚散完步', '我已经', '吃完了',
    ];
    return completedKeywords.any(lower.contains);
  }

  /// 检测用户是否表达"未完成/待完成"
  bool _detectPendingIntent(String text) {
    final lower = text.toLowerCase();
    final pendingKeywords = [
      '还没', '还没有', '没有', '没吃', '没做', '没喝', '没运动', '没散步',
      '待会', '等会', '等一下', '马上', '准备', '等一会儿', '稍后', '晚点',
      '记得', '别忘了', '要', '该', '马上做', '这就去',
    ];
    return pendingKeywords.any(lower.contains);
  }

  void _postpone(int minutes) {
    widget.store.postponeAgenda(widget.reminder.id, minutes);
    widget.store.dismissReminder();
  }

  void _close() {
    widget.store.dismissReminder();
    widget.store.setHomeOverlayOpen(false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Colors.black54),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active, color: AppColors.accent, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text('事程提醒', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('到了该做这件事的时间了', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Text(widget.reminder.time, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accent, fontFamily: 'monospace')),
                            if (widget.reminder.isMustDo) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(4)),
                                child: const Text('必做', style: TextStyle(fontSize: 11, color: AppColors.danger)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(widget.reminder.content, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 录音区域
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text('说一段话，让AI判断您是否已完成', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                        const SizedBox(height: 12),
                        if (!_analysisComplete)
                          GestureDetector(
                            onTapDown: (details) => _startRecording(),
                            onTapUp: (details) => _stopRecording(),
                            onTapCancel: () => _cancelRecording(),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isRecording ? AppColors.danger : AppColors.accent,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isRecording ? '录音中... ${_recordSeconds}秒' : '按住录音',
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isCompleted ? AppColors.successLight : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(_analysisResult, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _isCompleted ? AppColors.success : AppColors.warning)),
                                const SizedBox(height: 6),
                                Text('语音内容：$_recordText', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        if (_isAnalyzing)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 按钮区域
                  if (!_analysisComplete || !_isCompleted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              widget.store.completeAgenda(widget.reminder.id);
                              _close();
                            },
                            child: const Text('完成'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgTertiary, foregroundColor: AppColors.textSecondary),
                            onPressed: () => _postpone(10),
                            child: const Text('推迟10分'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgTertiary, foregroundColor: AppColors.textSecondary),
                            onPressed: () => _postpone(30),
                            child: const Text('推迟30分'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgTertiary, foregroundColor: AppColors.textTertiary),
                            onPressed: _close,
                            child: const Text('关闭'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _close,
                        child: const Text('知道了'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CreateAgendaModal extends StatefulWidget {
  final VoidCallback onClose;
  const CreateAgendaModal({super.key, required this.onClose});

  @override
  State<CreateAgendaModal> createState() => _CreateAgendaModalState();
}

class _CreateAgendaModalState extends State<CreateAgendaModal> {
  int _step = 0; // 0=入口选择, 1=语音创建, 2=文字创建, 3=常用事程

  // 文字创建状态
  final TextEditingController _contentCtrl = TextEditingController();
  String _selectedTime = '';
  AgendaLevel _selectedLevel = AgendaLevel.normal;

  // 语音创建状态
  bool _isRecording = false;
  String _voiceText = '';
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _step = step);
  }

  void _close() {
    widget.onClose();
  }

  void _createAgenda() {
    if (_contentCtrl.text.trim().isEmpty) return;
    final store = context.read<AppStore>();
    final icon = store.autoDetectIcon(_contentCtrl.text.trim());
    store.addAgenda(AgendaItem(
      id: '',
      content: _contentCtrl.text.trim(),
      time: _selectedTime,
      date: _ymd(DateTime.now()),
      icon: icon,
      isMustDo: _selectedLevel == AgendaLevel.mustDo,
      level: _selectedLevel,
      source: AgendaSource.user,
    ));
    _close();
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final frequentAgendas = store.frequentAgendas;

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black54),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.80),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 拖拽指示条 - 2.6.1 规范
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(9999), // full圆角
                    ),
                  ),
                  // 头部 - 包含返回按钮
                  _buildHeader(),
                  Flexible(
                    child: _step == 0
                        ? _buildStep0()
                        : _step == 1
                            ? _buildStep1()
                            : _step == 2
                                ? _buildStep2()
                                : _buildStep3(store, frequentAgendas),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String title = '';
    if (_step == 0) title = '创建事程';
    if (_step == 1) title = '按住说话';
    if (_step == 2) title = '创建事程';
    if (_step == 3) title = '常用事程';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          // 2.6.1 关闭按钮：24px X、textTertiary颜色
          if (_step == 0)
            GestureDetector(
              onTap: _close,
              child: Container(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.close,
                  size: 24,
                  color: AppColors.textTertiary,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _step = 0),
              child: Container(
                width: 24,
                height: 24,
                child: Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          if (title.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep0() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 语音创建 - 2.6.1: padding 16px、圆角14px、图标44px、背景accentLight
            GestureDetector(
              onTap: () => _goToStep(1),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(14), // --radius-lg
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 22), // 白色图标
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('语音创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.accent)), // 字号16px
                        const SizedBox(height: 2),
                        const Text('按住说话，自动识别内容和时间', style: TextStyle(fontSize: 13, color: AppColors.accent)), // 字号13px
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 文字创建 - 2.6.1: padding 16px、圆角14px、图标44px、背景bgTertiary
            GestureDetector(
              onTap: () => _goToStep(2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(14), // --radius-lg
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_note, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('文字创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), // 字号16px
                          const SizedBox(height: 2),
                          const Text('手动输入事程内容和时间', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)), // 字号13px
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            // 从常用事程选择 - 2.6.1: padding 16px、圆角14px、图标44px、背景bgTertiary
            GestureDetector(
              onTap: () => _goToStep(3),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(14), // --radius-lg
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('从常用事程选择', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), // 字号16px
                          const SizedBox(height: 2),
                          const Text('快速添加常用的高频行为', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)), // 字号13px
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 录音按钮 - 2.6.1 语音录入步骤
            GestureDetector(
              onTapDown: (details) => _startRecording(),
              onTapUp: (details) => _stopRecording(),
              onTapCancel: () => _cancelRecording(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isRecording ? AppColors.danger : AppColors.accent,
                  borderRadius: BorderRadius.circular(14), // --radius-lg
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isRecording ? '录音中... ${_recordSeconds}秒' : '按住说话，创建事程',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 识别结果提示
            if (_voiceText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(14), // --radius-lg
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    const Text('✨ 已识别，可修改后保存', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(_voiceText, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 图标选择 - 2.6.1: 48px圆形、背景bgTertiary、文字24px
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('📝', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(height: 16),
            // 内容输入 - 2.6.1: 背景 bgTertiary、圆角 --radius-md、padding 12px
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10), // --radius-md
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  hintText: '事程内容',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16),
            // 时间输入 - 2.6.1: Mono字体、带Clock图标、显示时间来源提示
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10), // --radius-md
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final timeParts = _selectedTime.split(':');
                      final initial = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
                      final picked = await showTimePicker(context: context, initialTime: initial);
                      if (picked != null) {
                        setState(() => _selectedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                      }
                    },
                    child: Text(
                      _selectedTime,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, fontFamily: 'monospace'), // Mono字体
                    ),
                  ),
                  const Spacer(),
                  Text('当前时间', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 级别选择 - 2.6.1: 三选一、普通、重要、必做
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications, size: 20, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    const Text('事程级别', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLevelButton(AgendaLevel.normal, '普通'),
                    const SizedBox(width: 8),
                    _buildLevelButton(AgendaLevel.important, '重要'),
                    const SizedBox(width: 8),
                    _buildLevelButton(AgendaLevel.mustDo, '必做'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('提醒策略可在「我的 → 提醒规则」中设置', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 24),
            // 创建按钮 - 2.6.1: 宽度100%、背景accent、颜色白色
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14), // --radius-lg
                  ),
                ),
                onPressed: _createAgenda,
                child: const Text('创建', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelButton(AgendaLevel level, String label) {
    final isSelected = _selectedLevel == level;
    // 2.6.1: 三选一、普通、重要、必做，使用对应颜色
    Color buttonColor;
    if (isSelected) {
      if (level == AgendaLevel.normal) buttonColor = AppColors.accent;
      else if (level == AgendaLevel.important) buttonColor = AppColors.warning;
      else buttonColor = AppColors.danger;
    } else {
      buttonColor = AppColors.bgTertiary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(14), // --radius-lg
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(AppStore store, List<FrequentAgenda> frequentAgendas) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // 提示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  const Text(
                    '系统已自动识别您的高频行为，点击添加为今日事程',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 列表
            if (frequentAgendas.isEmpty) ...[
              const SizedBox(height: 40),
              const Center(child: Text('暂无常用事程', style: TextStyle(fontSize: 14, color: AppColors.textTertiary))),
            ] else ...[
              Text('共 ${frequentAgendas.length} 项', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 12),
              ...frequentAgendas.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(item.content, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 6),
                                  if (item.matchRate >= 90)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('自动提取', style: TextStyle(fontSize: 10, color: AppColors.success)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text(item.avgTime, style: TextStyle(fontSize: 12, color: AppColors.textTertiary, fontFamily: 'monospace')),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.repeat, size: 12, color: AppColors.textTertiary),
                                  const SizedBox(width: 4),
                                  Text('连续${item.consecutiveDays}天', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${item.matchRate}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        store.addAgenda(AgendaItem(
                          id: '',
                          content: item.content,
                          time: item.avgTime,
                          date: _ymd(DateTime.now()),
                          icon: item.icon,
                          isHighFrequency: true,
                          source: AgendaSource.ai,
                        ));
                        _close();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('+ 添加为今日', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.accent)),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _startTimer();
  }

  void _startTimer() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 60) {
        _stopRecording();
        return;
      }
    }
  }

  void _stopRecording() {
    if (!_isRecording) return;
    setState(() => _isRecording = false);
    const voiceText = '记得下午3点吃药';
    setState(() => _voiceText = voiceText);
    // 直接创建事程，不待确认
    final store = context.read<AppStore>();
    store.submitVoiceRecordDirect(voiceText);
    // 2秒后自动关闭
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _close();
    });
  }

  void _cancelRecording() {
    setState(() {
      _isRecording = false;
      _voiceText = '';
    });
  }
}
