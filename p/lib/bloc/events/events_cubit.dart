import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/events_repository.dart';
import '../../models/event_model.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final EventsRepository eventsRepository;
  List<EventModel> _allEvents = [];
  String? _currentCategory;

  EventsCubit({required this.eventsRepository}) : super(const EventsInitial());

  Future<void> fetchEvents() async {
    emit(const EventsLoading());

    try {
      final events = await eventsRepository.fetchEvents();
      _allEvents = events;
      emit(EventsLoaded(events: events));
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  Future<void> searchEvents(String query) async {
    emit(const EventsLoading());

    try {
      final events = await eventsRepository.searchEvents(query);
      emit(EventsLoaded(events: events, selectedCategory: _currentCategory));
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  Future<void> filterByCategory(String? category) async {
    emit(const EventsLoading());

    try {
      _currentCategory = category;
      final events = category == null || category.isEmpty
          ? _allEvents
          : await eventsRepository.filterByCategory(category);
      emit(EventsLoaded(events: events, selectedCategory: category));
    } catch (e) {
      emit(EventsError(message: e.toString()));
    }
  }

  Future<EventModel?> getEventById(String id) async {
    try {
      return await eventsRepository.getEventById(id);
    } catch (e) {
      return null;
    }
  }

  void clearFilter() {
    _currentCategory = null;
    emit(EventsLoaded(events: _allEvents));
  }
}