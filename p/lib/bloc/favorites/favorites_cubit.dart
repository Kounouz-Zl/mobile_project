import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(const FavoritesState(favoriteEventIds: {}));

  void toggleFavorite(String eventId) {
    final favorites = Set<String>.from(state.favoriteEventIds);

    if (favorites.contains(eventId)) {
      favorites.remove(eventId);
    } else {
      favorites.add(eventId);
    }

    emit(state.copyWith(favoriteEventIds: favorites));
  }

  bool isFavorite(String eventId) {
    return state.favoriteEventIds.contains(eventId);
  }

  void clearFavorites() {
    emit(const FavoritesState(favoriteEventIds: {}));
  }
}