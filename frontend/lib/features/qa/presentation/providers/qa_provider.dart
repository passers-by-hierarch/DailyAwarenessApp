import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/qa_models.dart';

/// 问答消息状态管理
final qaMessagesProvider =
    StateNotifierProvider<QaMessagesNotifier, List<QaMessage>>(
  (ref) => QaMessagesNotifier(),
);

/// 处理中状态
final qaProcessingProvider = StateProvider<bool>((ref) => false);

/// 当前会话ID
final qaSessionIdProvider = StateProvider<String?>((ref) => null);

/// 历史记录
final qaHistoryProvider = FutureProvider<List<QaHistory>>((ref) async {
  // TODO: 从API获取历史记录
  return [];
});

class QaMessagesNotifier extends StateNotifier<List<QaMessage>> {
  QaMessagesNotifier() : super([]);

  void addMessage(QaMessage message) {
    state = [...state, message];
  }

  void updateLastMessage(QaMessage message) {
    if (state.isEmpty) return;
    state = [...state.sublist(0, state.length - 1), message];
  }

  void clear() {
    state = [];
  }
}

/// 问答服务类
class QaService {
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    String? sessionId,
  }) async {
    // TODO: 实现真实的API调用
    // 当前返回模拟数据
    await Future.delayed(const Duration(seconds: 1));

    return {
      'answer': '根据您的记录，钥匙放在玄关鞋柜的抽屉里。',
      'confidence': 0.96,
      'session_id': sessionId ?? 'new-session-id',
      'source_records': [
        {
          'id': 'record-001',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'content': '钥匙放在玄关鞋柜的抽屉里',
          'record_type': 'item',
          'relevance_score': 0.95,
          'source_name': '物品位置',
        },
      ],
    };
  }

  Future<List<QaHistory>> getHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    // TODO: 实现真实的历史记录获取
    return [];
  }

  Future<List<QaSession>> getSessions() async {
    // TODO: 实现真实的会话列表获取
    return [];
  }

  Future<void> endSession(String sessionId) async {
    // TODO: 实现真实的结束会话
  }
}

final qaServiceProvider = Provider<QaService>((ref) => QaService());
