import 'dart:async';
import 'package:flutter/foundation.dart';

/// 提醒推送服务
/// 当前为模拟实现，集成 flutter_local_notifications 后即可使用真实推送
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final Map<String, Timer> _activeTimers = {};
  final Map<String, int> _repeatCount = {};

  final _notificationController = StreamController<NotificationPayload>.broadcast();
  Stream<NotificationPayload> get notificationStream => _notificationController.stream;

  /// 初始化通知服务
  Future<void> initialize() async {
    // 实际集成 flutter_local_notifications 时的代码：
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const iosSettings = DarwinInitializationSettings();
    // const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    // await flutterLocalNotificationsPlugin.initialize(settings);
    debugPrint('[Notification] 通知服务已初始化');
  }

  /// 调度事程提醒
  /// [agendaId] 事程ID
  /// [title] 提醒标题
  /// [body] 提醒内容
  /// [scheduledTime] 提醒时间
  /// [advanceMinutes] 提前多少分钟提醒
  /// [repeatCount] 重复次数（间隔5分钟）
  /// [isMustDo] 是否必做（必做四阶段提醒）
  void scheduleAgendaReminder({
    required String agendaId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int advanceMinutes = 10,
    int repeatCount = 1,
    bool isMustDo = false,
  }) {
    cancelReminder(agendaId);

    if (isMustDo) {
      _scheduleMustDoReminders(agendaId, title, body, scheduledTime);
    } else {
      _scheduleNormalReminder(agendaId, title, body, scheduledTime, advanceMinutes, repeatCount);
    }
  }

  /// 必做四阶段提醒
  /// 阶段1：提前30分钟
  /// 阶段2：提前10分钟
  /// 阶段3：到时
  /// 阶段4：过后10分钟
  void _scheduleMustDoReminders(
    String agendaId,
    String title,
    String body,
    DateTime scheduledTime,
  ) {
    final stages = [
      {'offset': -30, 'msg': '30分钟后需要「$title」'},
      {'offset': -10, 'msg': '10分钟后需要「$title」'},
      {'offset': 0, 'msg': '现在需要「$title」'},
      {'offset': 10, 'msg': '「$title」已过10分钟，请尽快完成'},
    ];

    for (final stage in stages) {
      final offset = stage['offset'] as int;
      final msg = stage['msg'] as String;
      final remindTime = scheduledTime.add(Duration(minutes: offset));
      final delay = remindTime.difference(DateTime.now());

      if (delay.isNegative) continue; // 已过去的不调度

      final timerKey = '${agendaId}_stage_${offset}';
      _activeTimers[timerKey] = Timer(delay, () {
        _notificationController.add(NotificationPayload(
          id: agendaId,
          title: '事程提醒',
          body: msg,
          type: NotificationType.agenda,
          data: {'agendaId': agendaId, 'stage': offset},
        ));
        debugPrint('[Notification] 必做提醒: $msg');
      });
    }
  }

  /// 普通提醒
  void _scheduleNormalReminder(
    String agendaId,
    String title,
    String body,
    DateTime scheduledTime,
    int advanceMinutes,
    int repeatCount,
  ) {
    _repeatCount[agendaId] = 0;

    void scheduleNext() {
      if (_repeatCount[agendaId]! >= repeatCount) return;

      final remindTime = scheduledTime.subtract(Duration(minutes: advanceMinutes));
      final delay = remindTime.difference(DateTime.now());

      if (delay.isNegative) {
        _repeatCount[agendaId] = _repeatCount[agendaId]! + 1;
        scheduleNext();
        return;
      }

      _activeTimers[agendaId] = Timer(delay, () {
        _notificationController.add(NotificationPayload(
          id: agendaId,
          title: '事程提醒',
          body: '${advanceMinutes}分钟后需要「$title」',
          type: NotificationType.agenda,
          data: {'agendaId': agendaId, 'repeatIndex': _repeatCount[agendaId]},
        ));
        debugPrint('[Notification] 普通提醒: $title');

        _repeatCount[agendaId] = _repeatCount[agendaId]! + 1;
        if (_repeatCount[agendaId]! < repeatCount) {
          // 5分钟后再次提醒
          _activeTimers['${agendaId}_repeat'] = Timer(const Duration(minutes: 5), scheduleNext);
        }
      });
    }

    scheduleNext();
  }

  /// 检查当前时间是否在免打扰时段
  bool isQuietHours({required String start, required String end, required bool enabled}) {
    if (!enabled) return false;

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final startParts = start.split(':');
    final endParts = end.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    if (startMinutes < endMinutes) {
      // 同一天内（如 13:00-14:00）
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // 跨天（如 22:00-08:00）
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// 取消单个事程提醒
  void cancelReminder(String agendaId) {
    _activeTimers.remove(agendaId)?.cancel();
    _activeTimers.remove('${agendaId}_repeat')?.cancel();
    for (final key in _activeTimers.keys.toList()) {
      if (key.startsWith('${agendaId}_stage_')) {
        _activeTimers.remove(key)?.cancel();
      }
    }
    _repeatCount.remove(agendaId);
  }

  /// 取消所有提醒
  void cancelAll() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _repeatCount.clear();
  }

  /// 显示即时通知
  void showImmediate({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
  }) {
    _notificationController.add(NotificationPayload(
      id: 'immediate_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
    ));
  }

  void dispose() {
    cancelAll();
    _notificationController.close();
  }
}

/// 通知类型
enum NotificationType {
  agenda,      // 事程提醒
  inventory,   // 库存预警
  habit,       // 习惯提醒
  badge,       // 徽章奖励
  general,     // 通用
}

/// 通知数据
class NotificationPayload {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;

  const NotificationPayload({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = const {},
  });
}
