import '../models/user_model.dart';

class UserRepository {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 300));

  Future<UserModel> updateUsername(UserModel user, String username) async {
    await _delay();
    return user.copyWith(username: username);
  }

  Future<UserModel> updateProfilePhoto(UserModel user, String photoUrl) async {
    await _delay();
    return user.copyWith(profilePhotoUrl: photoUrl);
  }

  Future<UserModel> updateCategories(UserModel user, List<String> categories) async {
    await _delay();
    return user.copyWith(selectedCategories: categories);
  }
}