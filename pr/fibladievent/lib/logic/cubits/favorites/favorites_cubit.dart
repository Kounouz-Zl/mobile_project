import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorites_state.dart';
import '/../services/api_service.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final ApiService _apiService = ApiService();

  FavoritesCubit() : super(const FavoritesState(favoriteEventIds: {}));

  Future<void> setUserId(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId/favorites');
      final favorites = (response.data['favorites'] as List)
          .map((e) => e['event_id'] as String)
          .toSet();
      emit(state.copyWith(favoriteEventIds: favorites));
    } catch (e) {
      print('Error loading favorites for user $userId: $e');
    }
  }

  Future<void> loadFavorites() async {
    try {
      final response = await _apiService.get('/users/favorites');
      // Backend returns {favorites: [{event_id: ...}, ...]} or {favorites: [{...event objects...}]}
      final favoritesList = response.data['favorites'] as List? ?? [];
      final Set<String> favoriteIds = {};
      
      for (var item in favoritesList) {
        if (item is Map<String, dynamic>) {
          // If it's an event object, use the 'id' field
          if (item.containsKey('id')) {
            favoriteIds.add(item['id'] as String);
          }
          // If it's a favorite record with event_id field
          else if (item.containsKey('event_id')) {
            favoriteIds.add(item['event_id'] as String);
          }
        }
      }
      
      emit(state.copyWith(favoriteEventIds: favoriteIds));
      print('✅ Loaded ${favoriteIds.length} favorites');
    } catch (e) {
      print('❌ Error loading favorites: $e');
      // Don't clear favorites on error, keep existing state
    }
  }

  Future<void> toggleFavorite(String eventId) async {
    try {
      final favorites = Set<String>.from(state.favoriteEventIds);
      final wasFavorite = favorites.contains(eventId);

      if (wasFavorite) {
        // Remove from favorites
        favorites.remove(eventId);
        await _apiService.delete('/users/favorites/$eventId');
      } else {
        // Add to favorites
        favorites.add(eventId);
        await _apiService.post('/users/favorites/$eventId');
      }

      emit(state.copyWith(favoriteEventIds: favorites));
      print('✅ Toggle favorite $eventId: ${wasFavorite ? "removed" : "added"}');
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      // Revert on error - reload from server
      await loadFavorites();
    }
  }

  bool isFavorite(String eventId) {
    return state.favoriteEventIds.contains(eventId);
  }

  Future<void> clearFavorites() async {
    try {
      final favorites = List<String>.from(state.favoriteEventIds);
      for (var eventId in favorites) {
        await _apiService.delete('/favorites/$eventId');
      }
      emit(const FavoritesState(favoriteEventIds: {}));
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }
}
