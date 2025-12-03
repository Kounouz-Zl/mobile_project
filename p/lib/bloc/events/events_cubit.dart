import 'package:flutter_bloc/flutter_bloc.dart';
import '../../database_helper.dart';
import 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  EventsCubit() : super(EventsInitial());

  final dbHelper = DatabaseHelper();

  void fetchEvents() async {
    emit(EventsLoading());
    try {
      final events = await dbHelper.getEvents();
      emit(EventsLoaded(events));
    } catch (e) {
      emit(EventsError('Failed to fetch events'));
    }
  }

  void searchEvents(String query) {}
}
