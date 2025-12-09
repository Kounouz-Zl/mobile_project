
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '/../logic/cubits/favorites/favorites_cubit.dart';
import '/../logic/cubits/favorites/favorites_state.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/event.dart';
import '../events/event_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Event> favoriteEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => isLoading = true);

    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      final db = DatabaseHelper.instance;
      
      try {
        await context.read<FavoritesCubit>().loadFavorites();
        
        final favoriteIds = await db.getUserFavorites(userState.user.id);
        print('✅ Found ${favoriteIds.length} favorite IDs');
        
        final allEvents = await db.getAllEvents();
        final favorites = allEvents.where((event) => favoriteIds.contains(event.id)).toList();
        
        print('✅ Loaded ${favorites.length} favorite events');
        
        setState(() {
          favoriteEvents = favorites;
          isLoading = false;
        });
      } catch (e) {
        print('❌ Error loading favorites: $e');
        setState(() => isLoading = false);
      }
    } else {
      print('❌ User not loaded');
      setState(() => isLoading = false);
    }
  }

  Widget _buildEventImage(String imagePath, {double? width, double? height, BoxFit? fit}) {
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit ?? BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage(width, height);
          },
        );
      }
    }
    
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage(width, height);
      },
    );
  }

  Widget _buildPlaceholderImage(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey, size: 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WRAPPED with BlocBuilder for language changes
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F3FF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            // ✅ TRANSLATED
            title: Text(
              context.tr('my_favorites'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _loadFavorites,
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : favoriteEvents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: favoriteEvents.length,
                        itemBuilder: (context, index) {
                          final event = favoriteEvents[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildFavoriteCard(event),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.red.shade300,
            ),
          ),
          const SizedBox(height: 24),
          // ✅ TRANSLATED
          Text(
            context.tr('no_favorites'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          // ✅ TRANSLATED
          Text(
            context.tr('start_adding_favorites'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.explore),
            // ✅ TRANSLATED
            label: Text(context.tr('explore_events')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Event event) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
        
        if (result == true) {
          _loadFavorites();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildEventImage(
                    event.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                
                Positioned(
                  top: 12,
                  right: 12,
                  child: BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, state) {
                      final isFavorite = state.favoriteEventIds.contains(event.id);
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await context.read<FavoritesCubit>().toggleFavorite(event.id);
                            
                            // ✅ TRANSLATED
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite 
                                    ? context.tr('removed_from_favorites')
                                    : context.tr('added_to_favorites')),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            
                            _loadFavorites();
                          },
                        ),
                      );
                    },
                  ),
                ),
                
                if (event.category != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      // ✅ TRANSLATED
                      Text(
                        '${event.attendeesCount} ${context.tr('people_going')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}