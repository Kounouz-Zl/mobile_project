import '../models/user_model.dart';
import '../databases/database_helper.dart';

class AuthRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      // Validate inputs
      if (usernameOrEmail.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Please enter username/email and password');
      }

      final user = await _db.loginUser(usernameOrEmail.trim(), password);
      
      if (user == null) {
        throw Exception('Invalid credentials');
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signup(String email, String username, String password) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || username.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Please fill all fields');
      }

      // Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email');
      }

      // Validate username (alphanumeric, 3-20 characters)
      if (!_isValidUsername(username)) {
        throw Exception('Username must be 3-20 characters and contain only letters, numbers, and underscores');
      }

      // Validate password (at least 6 characters)
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final user = await _db.registerUser(
        email: email.trim(),
        username: username.trim(),
        password: password,
      );
      
      if (user == null) {
        throw Exception('Failed to create account');
      }

      // Auto login after signup
      return await _db.loginUser(username.trim(), password) ?? user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _db.logout();
  }

  Future<UserModel?> getCurrentUser() async {
    return await _db.getCurrentUser();
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      if (email.trim().isEmpty) {
        throw Exception('Please enter your email');
      }

      if (!_isValidEmail(email)) {
        throw Exception('Please enter a valid email');
      }

      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      await _db.resetPassword(email.trim(), newPassword);
    } catch (e) {
      rethrow;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }
}