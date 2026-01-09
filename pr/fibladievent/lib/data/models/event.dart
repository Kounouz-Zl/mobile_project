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
  final String? createdBy;

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
    this.createdBy,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Extract image URL with multiple fallback options
    String imageUrl = json['image_url'] ?? 
                     json['imageUrl'] ?? 
                     json['image'] ??
                     'https://via.placeholder.com/400x200';
    
    print('📸 Event image URL extracted: $imageUrl from json keys: ${json.keys}');
    
    return Event(
      id: json['id'] ?? json['_id'] ?? '',  // flexible
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      locationAddress: json['location_address'] ?? json['locationAddress'] ?? '',
      date: json['date'] ?? '',
      imageUrl: imageUrl,
      organizerName: json['organizer_name'] ?? json['organizerName'] ?? '',
      organizerImageUrl: json['organizer_image_url'] ?? json['organizerImageUrl'] ?? '',
      attendeesCount: json['attendees_count'] ?? json['attendees'] ?? 0,
      category: json['category'] ?? json['event_category'],
      createdBy: json['created_by'] ?? json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'location_address': locationAddress,
      'date': date,
      'image_url': imageUrl,
      'organizer_name': organizerName,
      'organizer_image_url': organizerImageUrl,
      'attendees_count': attendeesCount,
      'category': category,
      'created_by': createdBy,
    };
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
        createdBy,
      ];




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
    String? createdBy,
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
      createdBy: createdBy ?? this.createdBy,
    );
  }

}