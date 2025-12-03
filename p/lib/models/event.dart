import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String location;
  final String date;
  final String price;
  final String category;
  final String imagePath;

  const Event({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.price,
    required this.category,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [id, title, location, date, price, category, imagePath];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'date': date,
      'price': price,
      'category': category,
      'imagePath': imagePath,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      location: map['location'],
      date: map['date'],
      price: map['price'],
      category: map['category'],
      imagePath: map['imagePath'],
    );
  }
}
