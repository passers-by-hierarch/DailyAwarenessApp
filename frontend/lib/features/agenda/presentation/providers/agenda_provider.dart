import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/agenda.dart';
import '../../data/repositories/agenda_repository.dart';
import '../../../../core/network/api_client.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  final apiClient = ApiClient();
  return AgendaRepository(apiClient: apiClient);
});

class AgendaState {
  final List<Agenda> agendas;
  final List<BehaviorTag> behaviorTags;
  final bool isLoading;
  final String? error;

  AgendaState({
    this.agendas = const [],
    this.behaviorTags = const [],
    this.isLoading = false,
    this.error,
  });

  AgendaState copyWith({
    List<Agenda>? agendas,
    List<BehaviorTag>? behaviorTags,
    bool? isLoading,
    String? error,
  }) {
    return AgendaState(
      agendas: agendas ?? this.agendas,
      behaviorTags: behaviorTags ?? this.behaviorTags,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AgendaNotifier extends StateNotifier<AgendaState> {
  final AgendaRepository repository;

  AgendaNotifier({required this.repository}) : super(AgendaState());

  Future<void> loadTodayAgendas() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final agendas = await repository.getTodayAgendas();
      agendas.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
      state = state.copyWith(agendas: agendas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadBehaviorTags() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tags = await repository.getBehaviorTags();
      state = state.copyWith(behaviorTags: tags, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createAgenda({
    required DateTime plannedTime,
    required String content,
    String? behaviorTag,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final agenda = await repository.createAgenda(
        plannedTime: plannedTime,
        content: content,
        behaviorTag: behaviorTag,
      );
      final updatedAgendas = [...state.agendas, agenda];
      updatedAgendas.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
      state = state.copyWith(agendas: updatedAgendas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> confirmAgenda(String id) async {
    try {
      await repository.confirmAgenda(id);
      final updatedAgendas = state.agendas.map((a) {
        if (a.id == id) {
          return a.copyWith(status: 'completed');
        }
        return a;
      }).toList();
      state = state.copyWith(agendas: updatedAgendas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> snoozeAgenda(String id, {int minutes = 10}) async {
    try {
      await repository.snoozeAgenda(id, minutes: minutes);
      final updatedAgendas = state.agendas.map((a) {
        if (a.id == id) {
          return a.copyWith(
            status: 'snoozed',
            plannedTime: a.plannedTime.add(Duration(minutes: minutes)),
          );
        }
        return a;
      }).toList();
      updatedAgendas.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
      state = state.copyWith(agendas: updatedAgendas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> skipAgenda(String id) async {
    try {
      await repository.skipAgenda(id);
      final updatedAgendas = state.agendas.map((a) {
        if (a.id == id) {
          return a.copyWith(status: 'skipped');
        }
        return a;
      }).toList();
      state = state.copyWith(agendas: updatedAgendas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAgenda(String id) async {
    try {
      await repository.deleteAgenda(id);
      final updatedAgendas = state.agendas.where((a) => a.id != id).toList();
      state = state.copyWith(agendas: updatedAgendas);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> voiceCreateAgenda(String filePath) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final agenda = await repository.voiceCreateAgenda(filePath: filePath);
      final updatedAgendas = [...state.agendas, agenda];
      updatedAgendas.sort((a, b) => a.plannedTime.compareTo(b.plannedTime));
      state = state.copyWith(agendas: updatedAgendas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final agendaProvider =
    StateNotifierProvider<AgendaNotifier, AgendaState>((ref) {
  final repository = ref.watch(agendaRepositoryProvider);
  return AgendaNotifier(repository: repository);
});
