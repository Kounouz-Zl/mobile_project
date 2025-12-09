import 'package:flutter_bloc/flutter_bloc.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(const CategoriesState(selectedCategories: {}));

  void toggleCategory(String category) {
    final categories = Set<String>.from(state.selectedCategories);

    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }

    emit(state.copyWith(selectedCategories: categories));
  }

  bool isSelected(String category) {
    return state.selectedCategories.contains(category);
  }

  void clearCategories() {
    emit(const CategoriesState(selectedCategories: {}));
  }

  void setCategories(Set<String> categories) {
    emit(state.copyWith(selectedCategories: categories));
  }
}
