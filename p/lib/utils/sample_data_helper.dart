// utils/sample_data_helper.dart
import '../databases/database_helper.dart';
import '../models/event.dart';

class SampleDataHelper {
  static Future<void> insertSampleEvents() async {
    final db = DatabaseHelper.instance;

    final sampleEvents = [
      Event(
        id: '1',
        title: 'Darshan Raval\nMusic Show',
        description:
            'Enjoy your favorite dishes and a lovely your friends and family and have a great time. Food from local food trucks will be available for purchase. Come and experience an amazing musical night with Darshan Raval!',
        location: 'Jurmount club',
        locationAddress: '36 Guild Street London, UK',
        date: '03 May, 2023',
        imageUrl: 'https://via.placeholder.com/400x200',
        organizerName: 'OYONOW',
        organizerImageUrl: 'https://via.placeholder.com/100',
        attendeesCount: 20,
      ),
      Event(
        id: '2',
        title: 'International Music Festival',
        description:
            'A grand music festival featuring artists from around the world. Experience different genres and cultures in one place.',
        location: 'Central Park Arena',
        locationAddress: '123 Park Avenue, New York, USA',
        date: '15 June, 2023',
        imageUrl: 'https://via.placeholder.com/400x200',
        organizerName: 'Global Events Inc',
        organizerImageUrl: 'https://via.placeholder.com/100',
        attendeesCount: 150,
      ),
      Event(
        id: '3',
        title: 'Tech Conference 2023',
        description:
            'Join us for the biggest tech conference of the year. Learn from industry leaders and network with professionals.',
        location: 'Convention Center',
        locationAddress: '456 Tech Street, San Francisco, USA',
        date: '20 July, 2023',
        imageUrl: 'https://via.placeholder.com/400x200',
        organizerName: 'Tech Summit',
        organizerImageUrl: 'https://via.placeholder.com/100',
        attendeesCount: 500,
      ),
      Event(
        id: '4',
        title: 'Food & Wine Festival',
        description:
            'Discover amazing cuisines and fine wines from local and international vendors. A perfect evening for food lovers.',
        location: 'Riverside Gardens',
        locationAddress: '789 River Road, Chicago, USA',
        date: '10 August, 2023',
        imageUrl: 'https://via.placeholder.com/400x200',
        organizerName: 'Gourmet Events',
        organizerImageUrl: 'https://via.placeholder.com/100',
        attendeesCount: 80,
      ),
      Event(
        id: '5',
        title: 'Art Exhibition Opening',
        description:
            'Explore contemporary art from emerging artists. Join us for the opening night with live music and refreshments.',
        location: 'Modern Art Gallery',
        locationAddress: '321 Art Lane, Los Angeles, USA',
        date: '05 September, 2023',
        imageUrl: 'https://via.placeholder.com/400x200',
        organizerName: 'Art Collective',
        organizerImageUrl: 'https://via.placeholder.com/100',
        attendeesCount: 45,
      ),
    ];

    for (var event in sampleEvents) {
      await db.insertEvent(event);
    }

    print('Sample events inserted successfully!');
  }

  static Future<void> clearAllData() async {
    final db = DatabaseHelper.instance;
    final events = await db.getAllEvents();

    for (var event in events) {
      await db.deleteEvent(event.id);
    }

    print('All data cleared successfully!');
  }
}
