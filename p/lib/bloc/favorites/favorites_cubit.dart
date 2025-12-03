import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorites_state.dart';
import '../../databases/database_helper.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  FavoritesCubit() : super(const FavoritesState(favoriteEventIds: {})) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      final favorites = await _databaseHelper.getAllFavorites();
      emit(state.copyWith(favoriteEventIds: favorites.toSet()));
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String eventId) async {
    try {
      final favorites = Set<String>.from(state.favoriteEventIds);
      
      if (favorites.contains(eventId)) {
        favorites.remove(eventId);
        await _databaseHelper.removeFavorite(eventId);
      } else {
        favorites.add(eventId);
        await _databaseHelper.addFavorite(eventId);
      }
      
      emit(state.copyWith(favoriteEventIds: favorites));
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  bool isFavorite(String eventId) {
    return state.favoriteEventIds.contains(eventId);
  }

  Future<void> clearFavorites() async {
    try {
      final favorites = List<String>.from(state.favoriteEventIds);
      for (var eventId in favorites) {
        await _databaseHelper.removeFavorite(eventId);
      }
      emit(const FavoritesState(favoriteEventIds: {}));
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}