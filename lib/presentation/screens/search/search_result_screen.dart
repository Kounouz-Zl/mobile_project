
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/event.dart';
import '/../logic/cubits/favorites/favorites_cubit.dart';
import '/../logic/cubits/favorites/favorites_state.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../presentation/screens/events/event_details_screen.dart';


class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({Key? key}) : super(key: key);

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Event> allEvents = [];
  List<Event> filteredEvents = [];
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    setState(() => isLoading = true);
    
    final db = DatabaseHelper.instance;
    try {
      final events = await db.getAllEvents();
      setState(() {
        allEvents = events;
        filteredEvents = [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => isLoading = false);
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredEvents = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      final lowerQuery = query.toLowerCase();
      
      filteredEvents = allEvents.where((event) {
        final titleMatch = event.title.toLowerCase().contains(lowerQuery);
        final locationMatch = event.location.toLowerCase().contains(lowerQuery);
        final organizerMatch = event.organizerName.toLowerCase().contains(lowerQuery);
        final categoryMatch = event.category?.toLowerCase().contains(lowerQuery) ?? false;
        
        return titleMatch || locationMatch || organizerMatch || categoryMatch;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ WRAPPED with BlocBuilder
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F3FF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            // ✅ TRANSLATED
            title: Text(
              context.tr('search'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _performSearch,
                          style: const TextStyle(fontSize: 16),
                          // ✅ TRANSLATED
                          decoration: InputDecoration(
                            hintText: context.tr('search_events'),
                            border: InputBorder.none,
                            hintStyle: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isSearching || _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 60,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 24),
            // ✅ TRANSLATED
            Text(
              context.tr('search'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              // ✅ TRANSLATED
              child: Text(
                context.tr('search_events'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60,
                color: Colors.orange.shade300,
              ),
            ),
            const SizedBox(height: 24),
            // ✅ TRANSLATED
            Text(
              context.tr('no_upcoming'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSearchResultCard(event),
        );
      },
    );
  }

  Widget _buildSearchResultCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                event.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, color: Colors.grey, size: 40),
                  );
                },
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'By ${event.organizerName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) {
                  final isFavorite = state.favoriteEventIds.contains(event.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 28,
                    ),
                    onPressed: () async {
                      final userState = context.read<UserCubit>().state;
                      if (userState is UserLoaded) {
                        final db = DatabaseHelper.instance;
                        
                        if (isFavorite) {
                          await db.removeFavorite(event.id, userState.user.id);
                        } else {
                          await db.addFavorite(event.id, userState.user.id);
                        }
                        
                        context.read<FavoritesCubit>().toggleFavorite(event.id);
                        
                        // ✅ TRANSLATED
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite 
                                  ? context.tr('removed_from_favorites')
                                  : context.tr('added_to_favorites'),
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}