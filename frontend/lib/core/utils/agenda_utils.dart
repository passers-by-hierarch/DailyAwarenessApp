import '../models/app_models.dart';

/// 事程相关工具方法 - 消除多文件重复逻辑
class AgendaUtils {
  AgendaUtils._();

  /// 计算事程的有效状态
  /// 今日且时间已过的 pending/postponed 事程，实时转换为 expired
  static AgendaStatus effectiveStatus(AgendaItem item, {required bool isToday, DateTime? now}) {
    if ((item.status == AgendaStatus.pending || item.status == AgendaStatus.postponed) && isToday) {
      final parts = item.time.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final n = now ?? DateTime.now();
        final scheduled = DateTime(n.year, n.month, n.day, h, m);
        if (n.isAfter(scheduled)) {
          return AgendaStatus.expired;
        }
      }
    }
    return item.status;
  }

  /// 计算事程的剩余时间描述
  static String calculateRemainingTime(AgendaItem item, {required bool isToday, DateTime? now}) {
    if (!isToday) {
      return '待提醒';
    }
    final parts = item.time.split(':');
    if (parts.length != 2) return '今日提醒';
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final n = now ?? DateTime.now();
    final agendaTime = DateTime(n.year, n.month, n.day, h, m);
    final diff = agendaTime.difference(n);
    if (diff.isNegative) {
      return '已过期';
    }
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    String base;
    if (hours > 0) {
      base = '还有${hours}小时${minutes}分';
    } else if (minutes > 0) {
      base = '还有${minutes}分钟';
    } else {
      base = '即将开始';
    }
    if (item.status == AgendaStatus.postponed) {
      base = '已延期 · $base';
    }
    return base;
  }

  /// 今日日期字符串 YYYY-MM-DD
  static String todayStr({DateTime? now}) {
    final n = now ?? DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}
