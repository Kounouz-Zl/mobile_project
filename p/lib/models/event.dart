import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String description;
  final String location;
  final String locationAddress;
  final String date;
  final String imageUrl;
  final String organizerName;
  final String organizerImageUrl;
  final int attendeesCount;
  final String? category;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.locationAddress,
    required this.date,
    required this.imageUrl,
    required this.organizerName,
    required this.organizerImageUrl,
    this.attendeesCount = 0,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'locationAddress': locationAddress,
      'date': date,
      'imageUrl': imageUrl,
      'organizerName': organizerName,
      'organizerImageUrl': organizerImageUrl,
      'attendeesCount': attendeesCount,
      'category': category,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      locationAddress: json['locationAddress'] ?? '',
      date: json['date'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      organizerName: json['organizerName'] ?? '',
      organizerImageUrl: json['organizerImageUrl'] ?? '',
      attendeesCount: json['attendeesCount'] ?? 0,
      category: json['category'],
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? locationAddress,
    String? date,
    String? imageUrl,
    String? organizerName,
    String? organizerImageUrl,
    int? attendeesCount,
    String? category,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerName: organizerName ?? this.organizerName,
      organizerImageUrl: organizerImageUrl ?? this.organizerImageUrl,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        location,
        locationAddress,
        date,
        imageUrl,
        organizerName,
        organizerImageUrl,
        attendeesCount,
        category,
      ];
}