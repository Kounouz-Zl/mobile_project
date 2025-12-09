import 'package:flutter_bloc/flutter_bloc.dart';
import '/../data/repositories/events_repository.dart';
import '/../data/models/event_model.dart';
import '/../data/models/event.dart';
import '/../data/databases/database_helper.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  final EventsRepository eventsRepository;
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;
  List<Event> _allEvents = [];
  String _searchQuery = '';

  EventsCubit({required this.eventsRepository}) : super(EventsInitial());

  // Convert EventModel to Event
  Event _convertEventModelToEvent(EventModel model) {
    return Event(
      id: model.id,
      title: model.title,
      description: model.description,
      location: model.location,
      locationAddress: model.location, // Use location as address if not available
      date: model.date,
      imageUrl: model.imagePath,
      organizerName: model.organizer,
      organizerImageUrl: 'https://via.placeholder.com/100', // Default placeholder
      attendeesCount: model.attendees,
    );
  }

  Future<void> fetchEvents() async {
    emit(EventsLoading());

    try {
      // Fetch from both repository and database
      final repoEvents = await eventsRepository.fetchEvents();
      final dbEvents = await databaseHelper.getAllEvents();
      
      // Convert EventModel to Event
      final convertedRepoEvents = repoEvents.map((e) => _convertEventModelToEvent(e)).toList();
      
      // Combine and deduplicate by ID
      final Map<String, Event> eventsMap = {};
      for (var event in convertedRepoEvents) {
        eventsMap[event.id] = event;
      }
      for (var event in dbEvents) {
        eventsMap[event.id] = event;
      }
      
      _allEvents = eventsMap.values.toList();
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
      final repoEvents = await eventsRepository.searchEvents(query);
      final convertedRepoEvents = repoEvents.map((e) => _convertEventModelToEvent(e)).toList();
      
      // Also search in database events
      final dbEvents = await databaseHelper.getAllEvents();
      final filteredDbEvents = dbEvents.where((event) {
        return event.title.toLowerCase().contains(query.toLowerCase()) ||
            event.location.toLowerCase().contains(query.toLowerCase()) ||
            event.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
      
      // Combine results
      final Map<String, Event> eventsMap = {};
      for (var event in convertedRepoEvents) {
        eventsMap[event.id] = event;
      }
      for (var event in filteredDbEvents) {
        eventsMap[event.id] = event;
      }
      
      final filteredEvents = eventsMap.values.toList();
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
          : (await eventsRepository.filterByCategory(category))
              .map((e) => _convertEventModelToEvent(e))
              .toList();
      emit(EventsLoaded(events: events, searchQuery: _searchQuery));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<Event?> getEventById(String id) async {
    try {
      // First try database
      final dbEvent = await databaseHelper.getEventById(id);
      if (dbEvent != null) {
        return dbEvent;
      }
      
      // Then try repository
      final repoEvent = await eventsRepository.getEventById(id);
      if (repoEvent != null) {
        return _convertEventModelToEvent(repoEvent);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await databaseHelper.insertEvent(event);
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
      await databaseHelper.updateEvent(event);
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