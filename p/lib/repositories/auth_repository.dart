import '../models/user_model.dart';

class AuthRepository {
  // Simulated delay for API calls
  Future<void> _delay() => Future.delayed(const Duration(seconds: 1));

  Future<UserModel> login(String username, String password) async {
    await _delay();

    // Simulate validation
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Please enter username and password');
    }

    // Simulate successful login
    return UserModel(
      id: '1',
      email: 'user@example.com',
      username: username,
    );
  }

  Future<UserModel> signup(String email, String username, String password) async {
    await _delay();

    // Simulate validation
    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      throw Exception('Please fill all fields');
    }

    // Simulate successful signup
    return UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      username: username,
    );
  }

  Future<void> logout() async {
    await _delay();
    // Simulate logout
  }

  Future<UserModel?> getCurrentUser() async {
    await _delay();
    // Return null if no user is logged in
    return null;
  }
}