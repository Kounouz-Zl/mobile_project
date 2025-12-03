import 'package:equatable/equatable.dart';

class FavoritesState extends Equatable {
  final Set<String> favoriteEventIds;

  const FavoritesState(this.favoriteEventIds);

  @override
  List<Object> get props => [favoriteEventIds];
}
