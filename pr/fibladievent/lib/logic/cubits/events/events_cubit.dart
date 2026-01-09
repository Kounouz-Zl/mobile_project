import 'package:flutter_bloc/flutter_bloc.dart';
import '/../data/repositories/events_repository.dart';
import '/../data/models/event.dart';

import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final EventsRepository eventsRepository;
  List<Event> _allEvents = [];
  String _searchQuery = '';

  EventsCubit({required this.eventsRepository}) : super(EventsInitial());

  Future<void> fetchEvents() async {
    emit(EventsLoading());

    try {
      final repoEvents = await eventsRepository.getAllEvents();
      _allEvents = repoEvents;
      emit(EventsLoaded(events: _allEvents, searchQuery: _searchQuery));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> loadEvents() async {
    await fetchEvents();
  }

  Future<void> searchEvents(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      emit(EventsLoaded(events: _allEvents, searchQuery: ''));
      return;
    }

    try {
      // Filter events from the already loaded list
      final filteredEvents = _allEvents.where((event) {
        return event.title.toLowerCase().contains(query.toLowerCase()) ||
            event.location.toLowerCase().contains(query.toLowerCase()) ||
            event.description.toLowerCase().contains(query.toLowerCase());
      }).toList();

      emit(EventsLoaded(
        events: _allEvents,
        filteredEvents: filteredEvents,
        searchQuery: query,
      ));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> filterByCategory(String? category) async {
    emit(EventsLoading());

    try {
      final events = category == null || category.isEmpty
          ? _allEvents
          : _allEvents.where((event) {
              // Filter based on category if available
              return true; // Add category filtering logic as needed
            }).toList();
      emit(EventsLoaded(events: events, searchQuery: _searchQuery));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<Event?> getEventById(String id) async {
    try {
      final repoEvent = await eventsRepository.getEventById(id);
      return repoEvent;
    } catch (e) {
      return null;
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await eventsRepository.createEvent(event);
      _allEvents.add(event);
      emit(EventAdded(event));
      // Refresh the list
      await fetchEvents();
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      // Call API to update (you may need to add this method to EventsRepository)
      final index = _allEvents.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _allEvents[index] = event;
      }
      emit(EventUpdated(event));
      // Refresh the list
      await fetchEvents();
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  void resetFilters() {
    _searchQuery = '';
    emit(EventsLoaded(events: _allEvents, searchQuery: ''));
  }

  void clearFilter() {
    resetFilters();
  }
}
