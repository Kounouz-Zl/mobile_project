import '../models/event_model.dart';

class EventsRepository {
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 500));

  Future<List<EventModel>> fetchEvents() async {
    await _delay();

    // Return sample events
    return const [
      EventModel(
        id: '1',
        title: 'Satellite mega festival - 2023',
        location: 'New Ranip',
        imagePath: 'assets/images/event1.jpg',
        date: 'THU 26 May, 09:00',
        price: '\$30.00',
        category: 'Music',
        description: 'Amazing music festival with top artists',
        organizer: 'OYONOW',
        attendees: 20,
      ),
      EventModel(
        id: '2',
        title: 'show event something',
        location: 'Gota',
        imagePath: 'assets/images/event2.jpg',
        date: 'FRI 27 May, 10:00',
        price: '\$25.00',
        category: 'Community',
        description: 'Community gathering event',
        organizer: 'Events Co',
        attendees: 15,
      ),
      EventModel(
        id: '3',
        title: 'esec hackathoon for biggeners',
        location: 'Rajnunagar',
        imagePath: 'assets/images/event5.jpg',
        date: 'SAT 28 May, 14:00',
        price: 'Free',
        category: 'Science & Tech',
        description: 'Hackathon for beginners',
        organizer: 'ESEC',
        attendees: 30,
        isFree: true,
      ),
      EventModel(
        id: '4',
        title: 'Festival event at kudasan - 2022',
        location: 'Gota',
        imagePath: 'assets/images/event1.jpg',
        date: 'SUN 29 May, 18:00',
        price: 'Free',
        category: 'Community',
        description: 'Festival celebration',
        organizer: 'Kudasan Events',
        attendees: 50,
        isFree: true,
      ),
      EventModel(
        id: '5',
        title: 'Dance party at the top of the town - 2022',
        location: 'Rajnunagar',
        imagePath: 'assets/images/event5.jpg',
        date: 'MON 30 May, 20:00',
        price: '\$30.00',
        category: 'Music & Entertainment',
        description: 'Dance party with DJ',
        organizer: 'Party Masters',
        attendees: 40,
      ),
      EventModel(
        id: '6',
        title: 'hackathoon evnt',
        location: 'Chandlodiya',
        imagePath: 'assets/images/event3.jpg',
        date: 'TUE 31 May, 09:00',
        price: '\$20.00',
        category: 'Science & Tech',
        description: 'Tech hackathon event',
        organizer: 'Tech Hub',
        attendees: 25,
      ),
    ];
  }

  Future<List<EventModel>> searchEvents(String query) async {
    await _delay();
    final allEvents = await fetchEvents();

    if (query.isEmpty) return allEvents;

    return allEvents.where((event) {
      return event.title.toLowerCase().contains(query.toLowerCase()) ||
          event.location.toLowerCase().contains(query.toLowerCase()) ||
          event.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  Future<List<EventModel>> filterByCategory(String category) async {
    await _delay();
    final allEvents = await fetchEvents();

    if (category.isEmpty) return allEvents;

    return allEvents.where((event) {
      return event.category.toLowerCase() == category.toLowerCase();
    }).toList();
  }

  Future<EventModel?> getEventById(String id) async {
    await _delay();
    final allEvents = await fetchEvents();

    try {
      return allEvents.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }
}