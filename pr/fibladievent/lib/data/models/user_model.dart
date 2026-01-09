import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? profilePhotoUrl;
  final List<String> selectedCategories;
  final String role; // Add this line

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhotoUrl,
    this.selectedCategories = const [],
    this.role = 'participant', // Add this line with default value
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? profilePhotoUrl,
    List<String>? selectedCategories,
    String? role, // Add this line
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      role: role ?? this.role, // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'selectedCategories': selectedCategories,
      'role': role, // Add this line
    };
  }

factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
    username: json['username'] ?? '',
    profilePhotoUrl: json['profile_photo_url'],  // ✅ Fixed
    selectedCategories: List<String>.from(json['selected_categories'] ?? []),  // ✅ Fixed
    role: json['role'] ?? 'participant',
  );
}

  @override
  List<Object?> get props => [id, email, username, profilePhotoUrl, selectedCategories, role]; // Add role here
}