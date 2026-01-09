// bloc/user/user_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../data/models/user_model.dart';
import '/../services/api_service.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final ApiService _apiService = ApiService();
  UserModel? _currentUser;

  UserCubit() : super(const UserInitial());

  void setUser(UserModel user) {
    _currentUser = user;
    emit(UserLoaded(user: user));
  }

  Future<void> updateUsername(String username) async {
    if (_currentUser == null) return;

    emit(const UserLoading());

    try {
      final response = await _apiService
          .put('/users/profile/username', data: {'username': username});
      final updatedUser = UserModel.fromJson(response.data['user']);
      _currentUser = updatedUser;
      emit(UserLoaded(user: updatedUser));
    } catch (e) {
      emit(UserError(message: e.toString()));
      if (_currentUser != null) {
        emit(UserLoaded(user: _currentUser!));
      }
    }
  }

  Future<void> updateProfilePhoto(String photoPath) async {
    if (_currentUser == null) return;

    emit(const UserLoading());

    try {
      String photoUrl = photoPath;

      // If it's a local file path, upload it first
      if (photoPath.startsWith('/') ||
          photoPath.startsWith('file://') ||
          !photoPath.startsWith('http')) {
        final uploadResponse = await _apiService.uploadFile(
          '/users/profile/photo/upload',
          photoPath,
          fieldName: 'photo',
        );
        photoUrl = uploadResponse.data['url'] as String;
      }

      // Update user with the URL (either from upload or already a URL)
      final response = await _apiService
          .put('/users/profile/photo', data: {'photo_url': photoUrl});
      final updatedUser = UserModel.fromJson(response.data['user']);
      _currentUser = updatedUser;
      emit(UserLoaded(user: updatedUser));
    } catch (e) {
      emit(UserError(message: e.toString()));
      if (_currentUser != null) {
        emit(UserLoaded(user: _currentUser!));
      }
    }
  }

  Future<void> updateCategories(List<String> categories) async {
    if (_currentUser == null) return;

    emit(const UserLoading());

    try {
      final response = await _apiService
          .put('/users/profile/categories', data: {'categories': categories});
      final updatedUser = UserModel.fromJson(response.data['user']);
      _currentUser = updatedUser;
      emit(UserLoaded(user: updatedUser));
    } catch (e) {
      emit(UserError(message: e.toString()));
      if (_currentUser != null) {
        emit(UserLoaded(user: _currentUser!));
      }
    }
  }

  // ✅ NEW: Logout method
  void logout() {
    _currentUser = null;
    emit(const UserInitial());
  }

  UserModel? get currentUser => _currentUser;
}
