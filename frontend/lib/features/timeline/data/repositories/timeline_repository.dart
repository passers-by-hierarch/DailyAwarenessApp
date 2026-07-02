import 'package:dio/dio.dart';
import '../../data/models/timeline_record.dart';
import '../../../../core/network/api_client.dart';

class TimelineRepository {
  final ApiClient apiClient;

  TimelineRepository({required this.apiClient});

  Future<List<TimelineRecord>> getTodayTimeline() async {
    final response = await apiClient.dio.get('/timeline/today');
    final data = response.data['data'];
    if (data == null) return [];
    final List<dynamic> items = data['items'] ?? [];
    return items.map((e) => TimelineRecord.fromJson(e)).toList();
  }

  Future<List<TimelineRecord>> getHistoryTimeline({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await apiClient.dio.get(
      '/timeline/history',
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    final data = response.data['data'];
    if (data == null) return [];
    final List<dynamic> items = data['items'] ?? [];
    return items.map((e) => TimelineRecord.fromJson(e)).toList();
  }

  Future<TimelineRecord> createTimeline({
    required DateTime timestamp,
    required String content,
    String? behaviorTag,
  }) async {
    final response = await apiClient.dio.post(
      '/timeline',
      data: {
        'timestamp': timestamp.toIso8601String(),
        'content': content,
        if (behaviorTag != null) 'behavior_tag': behaviorTag,
      },
    );
    return TimelineRecord.fromJson(response.data['data']);
  }

  Future<TimelineRecord> updateTimeline({
    required String id,
    String? content,
    String? behaviorTag,
  }) async {
    final response = await apiClient.dio.put(
      '/timeline/$id',
      data: {
        if (content != null) 'content': content,
        if (behaviorTag != null) 'behavior_tag': behaviorTag,
      },
    );
    return TimelineRecord.fromJson(response.data['data']);
  }

  Future<void> deleteTimeline(String id) async {
    await apiClient.dio.delete('/timeline/$id');
  }

  Future<TimelineRecord> uploadVoiceTimeline({
    required String filePath,
    DateTime? timestamp,
  }) async {
    final formData = FormData.fromMap({
      'voice_file': await MultipartFile.fromFile(filePath),
      if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
    });

    final response = await apiClient.dio.post(
      '/timeline/voice',
      data: formData,
    );
    final data = response.data['data'];
    if (data is Map<String, dynamic> && data.containsKey('record')) {
      return TimelineRecord.fromJson(data['record']);
    }
    return TimelineRecord.fromJson(data);
  }
}
