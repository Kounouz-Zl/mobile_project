import 'package:equatable/equatable.dart';

class EventModel extends Equatable {
  final String id;
  final String title;
  final String location;
  final String imagePath;
  final String date;
  final String price;
  final String category;
  final String description;
  final String organizer;
  final int attendees;
  final bool isFree;

  const EventModel({
    required this.id,
    required this.title,
    required this.location,
    required this.imagePath,
    required this.date,
    required this.price,
    required this.category,
    required this.description,
    required this.organizer,
    this.attendees = 0,
    this.isFree = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'imagePath': imagePath,
      'date': date,
      'price': price,
      'category': category,
      'description': description,
      'organizer': organizer,
      'attendees': attendees,
      'isFree': isFree,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      imagePath: json['imagePath'] ?? '',
      date: json['date'] ?? '',
      price: json['price'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      organizer: json['organizer'] ?? '',
      attendees: json['attendees'] ?? 0,
      isFree: json['isFree'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        location,
        imagePath,
        date,
        price,
        category,
        description,
        organizer,
        attendees,
        isFree,
      ];
}

