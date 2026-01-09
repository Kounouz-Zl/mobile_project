/*import '../models/user_model.dart';
import '../databases/database_helper.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<UserModel> updateUsername(UserModel user, String username) async {
    try {
      if (username.trim().isEmpty) {
        throw Exception('Username cannot be empty');
      }

      if (!_isValidUsername(username)) {
        throw Exception('Username must be 3-20 characters and contain only letters, numbers, and underscores');
      }

      return await _db.updateUsername(user.id, username.trim());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfilePhoto(UserModel user, String photoUrl) async {
    try {
      return await _db.updateProfilePhoto(user.id, photoUrl);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateCategories(UserModel user, List<String> categories) async {
    try {
      return await _db.updateCategories(user.id, categories);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    return await _db.getUserById(userId);
  }

  Future<bool> checkUsernameExists(String username) async {
    return await _db.checkUsernameExists(username);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }
}*/

import '../models/user_model.dart';
import '../../services/api_service.dart';

class UserRepository {
  final ApiService _api = ApiService();

  Future<UserModel> updateUsername(UserModel user, String username) async {
    try {
      final response = await _api.put('/users/profile/username', 
        data: {'username': username});
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

  Future<UserModel> updateProfilePhoto(UserModel user, String photoUrl) async {
    try {
      final response = await _api.put('/users/profile/photo', 
        data: {'photo_url': photoUrl});
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      throw Exception('Failed to update photo: $e');
    }
  }

  Future<void> addFavorite(String eventId) async {
    try {
      await _api.post('/users/favorites/$eventId');
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  Future<void> removeFavorite(String eventId) async {
    try {
      await _api.delete('/users/favorites/$eventId');
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }
}
