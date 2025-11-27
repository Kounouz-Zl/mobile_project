import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? profilePhotoUrl;
  final List<String> selectedCategories;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.profilePhotoUrl,
    this.selectedCategories = const [],
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? profilePhotoUrl,
    List<String>? selectedCategories,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      selectedCategories: selectedCategories ?? this.selectedCategories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'selectedCategories': selectedCategories,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profilePhotoUrl: json['profilePhotoUrl'],
      selectedCategories: List<String>.from(json['selectedCategories'] ?? []),
    );
  }

  @override
  List<Object?> get props => [id, email, username, profilePhotoUrl, selectedCategories];
}