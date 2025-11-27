import 'package:equatable/equatable.dart';
import '../../models/event_model.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {
  const EventsInitial();
}

class EventsLoading extends EventsState {
  const EventsLoading();
}

class EventsLoaded extends EventsState {
  final List<EventModel> events;
  final String? selectedCategory;

  const EventsLoaded({
    required this.events,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [events, selectedCategory];
}

class EventsError extends EventsState {
  final String message;

  const EventsError({required this.message});

  @override
  List<Object?> get props => [message];
}
