import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/favorites/favorites_cubit.dart';
import '../bloc/favorites/favorites_state.dart';
import '../database_helper.dart';
import '../models/event.dart';
import 'event_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Events'),
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state.favoriteEventIds.isEmpty) {
            return const Center(
              child: Text(
                'You have no favorite events yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return FutureBuilder<List<Event>>(
            future: _getFavoriteEvents(state.favoriteEventIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading favorites.'));
              }

              final favoriteEvents = snapshot.data ?? [];

              if (favoriteEvents.isEmpty) {
                return const Center(
                  child: Text('No favorite events found.'),
                );
              }

              return ListView.builder(
                itemCount: favoriteEvents.length,
                itemBuilder: (context, index) {
                  final event = favoriteEvents[index];
                  return _buildFavoriteCard(event);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Event>> _getFavoriteEvents(Set<String> favoriteIds) async {
    final db = await DatabaseHelper().database;
    final List<Event> favoriteEvents = [];

    for (String id in favoriteIds) {
      final List<Map<String, dynamic>> maps = await db.query(
        'events',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        favoriteEvents.add(Event.fromMap(maps.first));
      }
    }

    return favoriteEvents;
  }

  Widget _buildFavoriteCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EventDetailsScreen(),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  event.imagePath,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, color: Colors.grey, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          event.location,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.date,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () {
                  context.read<FavoritesCubit>().toggleFavorite(event.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
