// bloc/user/user_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../data/repositories/user_repository.dart';
import '/../data/models/user_model.dart';
import 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;
  UserModel? _currentUser;

  UserCubit({required this.userRepository}) : super(const UserInitial());

  void setUser(UserModel user) {
    _currentUser = user;
    emit(UserLoaded(user: user));
  }

  Future<void> updateUsername(String username) async {
    if (_currentUser == null) return;

    emit(const UserLoading());

    try {
      final updatedUser = await userRepository.updateUsername(_currentUser!, username);
      _currentUser = updatedUser;
      emit(UserLoaded(user: updatedUser));
    } catch (e) {
      emit(UserError(message: e.toString()));
      if (_currentUser != null) {
        emit(UserLoaded(user: _currentUser!));
      }
    }
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return;

    emit(const UserLoading());

    try {
      final updatedUser = await userRepository.updateProfilePhoto(_currentUser!, photoUrl);
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
      final updatedUser = await userRepository.updateCategories(_currentUser!, categories);
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