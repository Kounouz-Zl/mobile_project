import 'package:equatable/equatable.dart';

class CategoriesState extends Equatable {
  final Set<String> selectedCategories;

  const CategoriesState({required this.selectedCategories});

  @override
  List<Object?> get props => [selectedCategories];

  CategoriesState copyWith({Set<String>? selectedCategories}) {
    return CategoriesState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }
}