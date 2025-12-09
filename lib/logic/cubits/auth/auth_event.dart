import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;

  const LoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class SignupRequested extends AuthEvent {
  final String email;
  final String username;
  final String password;
  final String role; // Added role field

  const SignupRequested({
    required this.email,
    required this.username,
    required this.password,
    required this.role, // 'participant' or 'organization'
  });

  @override
  List<Object?> get props => [email, username, password, role];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}