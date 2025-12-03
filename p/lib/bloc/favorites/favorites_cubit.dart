import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:p/database_helper.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final DatabaseHelper _dbHelper;

  FavoritesCubit(this._dbHelper) : super(const FavoritesState({}));

  void fetchFavorites() async {
    final favoriteIds = await _dbHelper.getFavoriteEventIds();
    emit(FavoritesState(favoriteIds.toSet()));
  }

  void toggleFavorite(String eventId) async {
    final isCurrentlyFavorite = state.favoriteEventIds.contains(eventId);
    if (isCurrentlyFavorite) {
      await _dbHelper.deleteFavorite(eventId);
    } else {
      await _dbHelper.insertFavorite(eventId);
    }
    fetchFavorites();
  }
}
