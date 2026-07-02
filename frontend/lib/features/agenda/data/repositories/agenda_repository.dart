import 'package:dio/dio.dart';
import '../../data/models/agenda.dart';
import '../../../../core/network/api_client.dart';

class AgendaRepository {
  final ApiClient apiClient;

  AgendaRepository({required this.apiClient});

  Future<List<Agenda>> getTodayAgendas() async {
    final response = await apiClient.dio.get('/agendas/today');
    final data = response.data['data'];
    if (data == null) return [];
    final List<dynamic> items = data['items'] ?? [];
    return items.map((e) => Agenda.fromJson(e)).toList();
  }

  Future<Agenda> getAgendaDetail(String id) async {
    final response = await apiClient.dio.get('/agendas/$id');
    return Agenda.fromJson(response.data['data']);
  }

  Future<Agenda> createAgenda({
    required DateTime plannedTime,
    required String content,
    String? behaviorTag,
    int remindOffset = 5,
    String remindLevel = 'standard',
    bool isRecurring = false,
    String? recurringRule,
  }) async {
    final response = await apiClient.dio.post(
      '/agendas',
      data: {
        'planned_time': plannedTime.toIso8601String(),
        'content': content,
        if (behaviorTag != null) 'behavior_tag': behaviorTag,
        'remind_offset': remindOffset,
        'remind_level': remindLevel,
        'is_recurring': isRecurring,
        if (recurringRule != null) 'recurring_rule': recurringRule,
      },
    );
    return Agenda.fromJson(response.data['data']);
  }

  Future<Agenda> updateAgenda({
    required String id,
    DateTime? plannedTime,
    String? content,
    String? behaviorTag,
    int? remindOffset,
    String? remindLevel,
  }) async {
    final response = await apiClient.dio.put(
      '/agendas/$id',
      data: {
        if (plannedTime != null) 'planned_time': plannedTime.toIso8601String(),
        if (content != null) 'content': content,
        if (behaviorTag != null) 'behavior_tag': behaviorTag,
        if (remindOffset != null) 'remind_offset': remindOffset,
        if (remindLevel != null) 'remind_level': remindLevel,
      },
    );
    return Agenda.fromJson(response.data['data']);
  }

  Future<void> confirmAgenda(String id) async {
    await apiClient.dio.post('/agendas/$id/confirm');
  }

  Future<void> snoozeAgenda(String id, {int minutes = 10}) async {
    await apiClient.dio.post(
      '/agendas/$id/snooze',
      data: {'minutes': minutes},
    );
  }

  Future<void> skipAgenda(String id) async {
    await apiClient.dio.post('/agendas/$id/skip');
  }

  Future<void> deleteAgenda(String id) async {
    await apiClient.dio.delete('/agendas/$id');
  }

  Future<Agenda> voiceCreateAgenda({
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'voice_file': await MultipartFile.fromFile(filePath),
    });

    final response = await apiClient.dio.post(
      '/agendas/voice',
      data: formData,
    );
    final data = response.data['data'];
    if (data is Map<String, dynamic> && data.containsKey('agenda')) {
      return Agenda.fromJson(data['agenda']);
    }
    return Agenda.fromJson(data);
  }

  Future<List<BehaviorTag>> getBehaviorTags() async {
    final response = await apiClient.dio.get('/behavior-tags');
    final data = response.data['data'];
    if (data == null) return [];
    final List<dynamic> items = data['items'] ?? [];
    return items.map((e) => BehaviorTag.fromJson(e)).toList();
  }
}
