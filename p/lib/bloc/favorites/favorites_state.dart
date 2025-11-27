import 'package:equatable/equatable.dart';

class FavoritesState extends Equatable {
  final Set<String> favoriteEventIds;

  const FavoritesState({required this.favoriteEventIds});

  @override
  List<Object?> get props => [favoriteEventIds];

  FavoritesState copyWith({Set<String>? favoriteEventIds}) {
    return FavoritesState(
      favoriteEventIds: favoriteEventIds ?? this.favoriteEventIds,
    );
  }
}