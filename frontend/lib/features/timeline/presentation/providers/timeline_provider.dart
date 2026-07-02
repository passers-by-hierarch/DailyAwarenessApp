import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/timeline_record.dart';
import '../../data/repositories/timeline_repository.dart';
import '../../../../core/network/api_client.dart';

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final apiClient = ApiClient();
  return TimelineRepository(apiClient: apiClient);
});

class TimelineState {
  final List<TimelineRecord> records;
  final bool isLoading;
  final String? error;

  TimelineState({
    this.records = const [],
    this.isLoading = false,
    this.error,
  });

  TimelineState copyWith({
    List<TimelineRecord>? records,
    bool? isLoading,
    String? error,
  }) {
    return TimelineState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final TimelineRepository repository;

  TimelineNotifier({required this.repository}) : super(TimelineState());

  Future<void> loadTodayTimeline() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final records = await repository.getTodayTimeline();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(records: records, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createTimeline({
    required DateTime timestamp,
    required String content,
    String? behaviorTag,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final record = await repository.createTimeline(
        timestamp: timestamp,
        content: content,
        behaviorTag: behaviorTag,
      );
      final updatedRecords = [...state.records, record];
      updatedRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(records: updatedRecords, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateTimeline({
    required String id,
    String? content,
    String? behaviorTag,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedRecord = await repository.updateTimeline(
        id: id,
        content: content,
        behaviorTag: behaviorTag,
      );
      final updatedRecords = state.records.map((r) {
        return r.id == id ? updatedRecord : r;
      }).toList();
      state = state.copyWith(records: updatedRecords, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteTimeline(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await repository.deleteTimeline(id);
      final updatedRecords = state.records.where((r) => r.id != id).toList();
      state = state.copyWith(records: updatedRecords, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> uploadVoiceTimeline(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final record = await repository.uploadVoiceTimeline(filePath: filePath);
      final updatedRecords = [...state.records, record];
      updatedRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(records: updatedRecords, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final timelineProvider =
    StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  final repository = ref.watch(timelineRepositoryProvider);
  return TimelineNotifier(repository: repository);
});
