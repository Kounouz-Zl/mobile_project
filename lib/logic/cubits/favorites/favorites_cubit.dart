import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorites_state.dart';
import '/../data/databases/database_helper.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  String? _currentUserId;

  FavoritesCubit() : super(const FavoritesState(favoriteEventIds: {}));

  void setUserId(String userId) {
    _currentUserId = userId;
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    if (_currentUserId == null) return;
    
    try {
      final favorites = await _databaseHelper.getUserFavorites(_currentUserId!);
      emit(state.copyWith(favoriteEventIds: favorites.toSet()));
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String eventId) async {
    if (_currentUserId == null) return;
    
    try {
      final favorites = Set<String>.from(state.favoriteEventIds);
      
      if (favorites.contains(eventId)) {
        favorites.remove(eventId);
        await _databaseHelper.removeFavorite(eventId, _currentUserId!);
      } else {
        favorites.add(eventId);
        await _databaseHelper.addFavorite(eventId, _currentUserId!);
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
    if (_currentUserId == null) return;
    
    try {
      final favorites = List<String>.from(state.favoriteEventIds);
      for (var eventId in favorites) {
        await _databaseHelper.removeFavorite(eventId, _currentUserId!);
      }
      emit(const FavoritesState(favoriteEventIds: {}));
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}