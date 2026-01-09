import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/favorites/favorites_cubit.dart';
import '/../logic/cubits/favorites/favorites_state.dart';
import '/../services/api_service.dart';
import '/../data/models/event.dart';
import '../search/search_result_screen.dart';
import '../events/event_details_screen.dart';
import '../events/events_screen.dart';
import '../events/add_event_screen.dart';
import '../favorites/favourites_screan.dart';
import '../events/popular_events_screen.dart';
import '../events/upcoming_events_screen.dart';
import '../events/recommended_events_screen.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '../profile/profile_screen.dart';
import '../../screens/notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final ApiService _apiService = ApiService();

  List<Event> popularEvents = [];
  List<Event> upcomingEvents = [];
  List<Event> recommendedEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeFavorites();
    _loadHomeEvents();
  }

  Future<void> _initializeFavorites() async {
    if (!mounted) return;
    final favoritesCubit = context.read<FavoritesCubit>();
    await favoritesCubit.loadFavorites();
    if (mounted) {
      print(
          'âœ… Favorites initialized with ${favoritesCubit.state.favoriteEventIds.length} items');
    }
  }

  Future<void> _loadHomeEvents() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Make API calls - limit is passed as integer
      final popularResponse = await _apiService.get('/events/popular', 
          queryParameters: {'limit': 4});
      final upcomingResponse = await _apiService
          .get('/events/upcoming', queryParameters: {'limit': 4});
      final recommendedResponse = await _apiService
          .get('/events/recommended', queryParameters: {'limit': 4});

      // Parse responses - check if data exists and is a list
      List<Event> popular = [];
      List<Event> upcoming = [];
      List<Event> recommended = [];

      if (popularResponse.data != null && popularResponse.data['events'] != null) {
        final eventsList = popularResponse.data['events'] as List?;
        if (eventsList != null) {
          popular = eventsList
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      if (upcomingResponse.data != null && upcomingResponse.data['events'] != null) {
        final eventsList = upcomingResponse.data['events'] as List?;
        if (eventsList != null) {
          upcoming = eventsList
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      if (recommendedResponse.data != null && recommendedResponse.data['events'] != null) {
        final eventsList = recommendedResponse.data['events'] as List?;
        if (eventsList != null) {
          recommended = eventsList
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      // Limit to 4 items max (already done by backend, but double-check)
      final popularPreview = popular.length > 4 ? popular.sublist(0, 4) : popular;
      final upcomingPreview = upcoming.length > 4 ? upcoming.sublist(0, 4) : upcoming;
      final recommendedPreview = recommended.length > 4 ? recommended.sublist(0, 4) : recommended;

      print('✅ Loaded home events: ${popularPreview.length} popular, ${upcomingPreview.length} upcoming, ${recommendedPreview.length} recommended');

      if (mounted) {
        setState(() {
          popularEvents = popularPreview;
          upcomingEvents = upcomingPreview;
          recommendedEvents = recommendedPreview;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading home events: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          popularEvents = [];
          upcomingEvents = [];
          recommendedEvents = [];
          isLoading = false;
        });
      }
    }
  }

  Future<int> _getUnreadNotificationCount() async {
    try {
      final response = await _apiService.get('/notifications/unread-count');
      if (response.data is Map<String, dynamic>) {
        return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return 0;
    }
  }

  Widget _buildEventImage(String imagePath,
      {double? width, double? height, BoxFit? fit}) {
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
    // âœ… WRAPPED with BlocBuilder for language changes
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 66, 22, 79),
                  ),
                )
              : _buildHomeContent(),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: Column(
        children: [
          // Search Bar and Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchResultScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          // âœ… CHANGED: Using context.tr() for translation
                          Text(
                            context.tr('search events'),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      // Unread badge
                      FutureBuilder<int>(
                        future: _getUnreadNotificationCount(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > 0) {
                            return Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 10,
                                  minHeight: 10,
                                ),
                                child: Text(
                                  '${snapshot.data}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadHomeEvents,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Upcoming Events Section
                    // âœ… CHANGED: Using context.tr() for section title
                    _buildSectionHeader(
                      context,
                      context.tr('upcoming_events'),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpcomingEventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (upcomingEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        // âœ… CHANGED: Using context.tr() for empty message
                        child: Text(
                          context.tr('no_upcoming'),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...upcomingEvents.map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildUpcomingEventCard(context, event),
                          )),
                    const SizedBox(height: 24),

                    // Popular Now Section
                    // âœ… CHANGED: Using context.tr() for section title
                    _buildSectionHeader(
                      context,
                      context.tr('popular_now'),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PopularEventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (popularEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        // âœ… CHANGED: Using context.tr() for empty message
                        child: Text(
                          context.tr('no_upcoming'),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popularEvents.length,
                          itemBuilder: (context, index) {
                            final event = popularEvents[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: _buildPopularCard(context, event),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Recommendations Section
                    // âœ… CHANGED: Using context.tr() for section title
                    _buildSectionHeader(
                      context,
                      context.tr('recommendations'),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecommendedEventsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (recommendedEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        // âœ… CHANGED: Using context.tr() for empty message
                        child: Text(
                          context.tr('no_upcoming'),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...recommendedEvents.map(
                          (event) => _buildRecommendationCard(context, event)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildCategoryChip removed (unused)

  Widget _buildSectionHeader(
      BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            // âœ… CHANGED: Using context.tr() for "See All" button
            child: Text(context.tr('see_all')),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventCard(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: _buildEventImage(
                  event.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                color: Colors.grey.shade600,
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
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                // âœ… CHANGED: Using context.tr() for "Join" button
                child: Text(
                  context.tr('join'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularCard(BuildContext context, Event event) {
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
        width: 200,
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
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildEventImage(
                    event.imageUrl,
                    width: 200,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_movies,
                            size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Event',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, state) {
                      final isFavorite =
                          state.favoriteEventIds.contains(event.id);

                      return GestureDetector(
                        onTap: () async {
                          final wasFavorite = isFavorite;
                          await context
                              .read<FavoritesCubit>()
                              .toggleFavorite(event.id);

                          // Show message based on NEW state (opposite of what it was)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(wasFavorite
                                  ? context.tr('removed_from_favorites')
                                  : context.tr('added_to_favorites')),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.date,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(Icons.person,
                                  size: 12, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // âœ… CHANGED: Using context.tr() for "going" text
                      Text(
                        '${event.attendeesCount} ${context.tr('people_going')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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

  Widget _buildRecommendationCard(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: _buildEventImage(
                  event.imageUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
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
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${event.attendeesCount}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, userState) {
        final isOrganizer =
            userState is UserLoaded && userState.user.role == 'organization';

        return _buildBottomNavBarContent(isOrganizer);
      },
    );
  }

  Widget _buildBottomNavBarContent(bool isOrganizer) {
    // âœ… CHANGED: All navigation labels now use context.tr()
    List<BottomNavigationBarItem> navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.explore_outlined),
        activeIcon: const Icon(Icons.explore),
        label: context.tr('explore'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_today_outlined),
        activeIcon: const Icon(Icons.calendar_today),
        label: context.tr('events'),
      ),
    ];

    if (isOrganizer) {
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 40),
          label: '',
        ),
      );
    }

    navItems.addAll([
      BottomNavigationBarItem(
        icon: const Icon(Icons.favorite_border),
        activeIcon: const Icon(Icons.favorite),
        label: context.tr('favorite'),
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: context.tr('profile'),
      ),
    ]);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.purple.shade700,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          if (isOrganizer) {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEventScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
            }
          } else {
            switch (index) {
              case 0:
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                ).then((_) {
                  setState(() => _currentIndex = 0);
                });
                break;
            }
          }
        },
        items: navItems,
      ),
    );
  }
}
