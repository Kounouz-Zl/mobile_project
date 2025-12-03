// bloc/events/events_state.dart
import 'package:equatable/equatable.dart';
import '../../models/event.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<Event> events;
  final List<Event> filteredEvents;
  final String searchQuery;

  const EventsLoaded({
    required this.events,
    this.filteredEvents = const [],
    this.searchQuery = '',
  });

  EventsLoaded copyWith({
    List<Event>? events,
    List<Event>? filteredEvents,
    String? searchQuery,
  }) {
    return EventsLoaded(
      events: events ?? this.events,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [events, filteredEvents, searchQuery];
}

class EventsError extends EventsState {
  final String message;

  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}

class EventAdded extends EventsState {
  final Event event;

  const EventAdded(this.event);

  @override
  List<Object?> get props => [event];
}

class EventUpdated extends EventsState {
  final Event event;

  const EventUpdated(this.event);

  @override
  List<Object?> get props => [event];
}

class EventDeleted extends EventsState {
  final String eventId;

  const EventDeleted(this.eventId);

  @override
  List<Object?> get props => [eventId];
}