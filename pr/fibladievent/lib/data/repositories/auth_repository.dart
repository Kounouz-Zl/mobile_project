/*import '../models/user_model.dart';
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

  Future<UserModel> signup({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
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
        role: role, // Pass role to database
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
}*/




import '../models/user_model.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final ApiService _api = ApiService();

  Future<UserModel> login(String usernameOrEmail, String password) async {
    try {
      // Trim and lowercase input to match backend expectations
      final input = usernameOrEmail.trim().toLowerCase();

      print('🔐 Attempting login with: ${input.isEmpty ? "empty" : "***"}');

      final response = await _api.post('/auth/login', data: {
        'username_or_email': input,
        'password': password,
      });

      print('✅ Login response status: ${response.statusCode}');

      // Check response status
      if (response.statusCode == null || response.statusCode! >= 400) {
        final errorMsg = response.data is Map<String, dynamic> 
            ? (response.data['error'] ?? 'Invalid credentials')
            : 'Invalid credentials';
        print('❌ Login error: $errorMsg');
        throw Exception(errorMsg);
      }

      // Save access token
      final session = response.data['session'];
      if (session == null || session['access_token'] == null) {
        print('❌ No session or access token in response');
        throw Exception('Login failed: No session returned');
      }
      
      final accessToken = session['access_token'];
      await _api.saveToken(accessToken);
      print('✅ Token saved successfully');

      // Parse user
      final userData = response.data['user'];
      if (userData == null) {
        print('❌ No user data in response');
        throw Exception('Login failed: No user data returned');
      }

      return UserModel(
        id: userData['id'],
        email: userData['email'],
        username: userData['username'],
        role: userData['role'] ?? 'participant',
        selectedCategories: List<String>.from(userData['selectedCategories'] ?? []),
        profilePhotoUrl: userData['profilePhotoUrl'],
      );
    } on DioException catch (e) {
      // Handle Dio-specific errors
      print('❌ DioException during login: ${e.message}');
      print('❌ Response data: ${e.response?.data}');
      final errorMsg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['error'] ?? 'Invalid credentials')
          : 'Invalid credentials';
      throw Exception(errorMsg);
    } catch (e) {
      print('❌ General exception during login: $e');
      // Don't wrap in another exception - preserve the original error message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<UserModel> signup({
    required String email,
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _api.post('/auth/signup', data: {
        'email': email.trim().toLowerCase(),
        'username': username.trim().toLowerCase(),
        'password': password,
        'role': role,
      });

      if (response.statusCode != 201) {
        throw Exception(response.data['error'] ?? 'Signup failed');
      }

      // Save token immediately
      final accessToken = response.data['session']['access_token'];
      await _api.saveToken(accessToken);

      final userData = response.data['user'];
      return UserModel(
        id: userData['id'],
        email: userData['email'],
        username: userData['username'],
        role: userData['role'] ?? 'participant',
        selectedCategories: List<String>.from(userData['selectedCategories'] ?? []),
        profilePhotoUrl: userData['profilePhotoUrl'],
      );
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
      await _api.clearToken();
    } catch (e) {
      await _api.clearToken();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _api.get('/auth/me');
      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      return null;
    }
  }
}
