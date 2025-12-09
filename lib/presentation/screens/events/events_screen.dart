// events_screen.dart - COMPLETE FIXED VERSION WITH INTERNATIONALIZATION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/event.dart';
import 'event_details_screen.dart';
import '../home/home_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isUpcomingSelected = true;
  List<Event> upcomingEvents = [];
  List<Event> pastEvents = [];
  bool isLoading = true;
  String? currentUserId;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserEvents();
  }

  Future<void> _loadUserEvents() async {
    setState(() => isLoading = true);
    
    final userState = context.read<UserCubit>().state;
    
    if (userState is UserLoaded) {
      currentUserId = userState.user.id;
      userRole = userState.user.role;
      final db = DatabaseHelper.instance;
      
      try {
        List<Event> upcoming = [];
        List<Event> past = [];

        // ✅ FIXED: Different queries based on user role
        if (userRole == 'organization') {
          // For organizations: show events they CREATED
          upcoming = await db.getOrganizerUpcomingEvents(currentUserId!);
          past = await db.getOrganizerPastEvents(currentUserId!);
        } else {
          // For participants: show events they JOINED
          upcoming = await db.getUserUpcomingEvents(currentUserId!);
          past = await db.getUserPastEvents(currentUserId!);
        }
        
        setState(() {
          upcomingEvents = upcoming;
          pastEvents = past;
          isLoading = false;
        });
        
        print('✅ Loaded ${upcoming.length} upcoming, ${past.length} past events for $userRole');
      } catch (e) {
        print('❌ Error loading user events: $e');
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  // Helper method to display image from database (file path or URL)
  Widget _buildEventImage(String imagePath, {double? width, double? height, BoxFit? fit}) {
    // Check if it's a local file path
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
    
    // Otherwise, treat as network URL
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
            title: Text(
              AppLocalizations.of(context)!.translate('events'),
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
                onPressed: _loadUserEvents,
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 20),
              // Tab Switcher
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab(AppLocalizations.of(context)!.translate('upcoming'), isUpcomingSelected, () {
                        setState(() {
                          isUpcomingSelected = true;
                        });
                      }),
                      _buildTab(AppLocalizations.of(context)!.translate('past_events'), !isUpcomingSelected, () {
                        setState(() {
                          isUpcomingSelected = false;
                        });
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Events List or Empty State
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5E83),
                        ),
                      )
                    : _buildEventsList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventsList() {
    final events = isUpcomingSelected ? upcomingEvents : pastEvents;
    
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserEvents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEventCard(event),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Calendar Icon
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 160,
                height: 140,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Calendar Header
                    Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5252),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCalendarTab(),
                          _buildCalendarTab(),
                        ],
                      ),
                    ),
                    // Calendar Grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCalendarRow(),
                            _buildCalendarRow(),
                            _buildCalendarRow(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Clock Icon
              Positioned(
                right: -10,
                bottom: 10,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF5F3FF), width: 4),
                  ),
                  child: CustomPaint(
                    painter: ClockPainter(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Text
          Text(
            isUpcomingSelected 
                ? AppLocalizations.of(context)!.translate('no_upcoming_events')
                : AppLocalizations.of(context)!.translate('no_past_events'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isUpcomingSelected 
                ? (userRole == 'organization' 
                    ? AppLocalizations.of(context)!.translate('create_events_to_see_them_here')
                    : AppLocalizations.of(context)!.translate('join_events_to_see_them_here'))
                : (userRole == 'organization'
                    ? AppLocalizations.of(context)!.translate('your_created_events_will_appear_here')
                    : AppLocalizations.of(context)!.translate('your_attended_events_will_appear_here')),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Explore Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E83),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('explore_events'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
        
        // Refresh the list if user joined/left an event
        if (result == true) {
          _loadUserEvents();
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
            // Event Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildEventImage(
                    event.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUpcomingSelected 
                          ? Colors.green.shade400 
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUpcomingSelected 
                              ? Icons.schedule 
                              : Icons.check_circle,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUpcomingSelected 
                              ? AppLocalizations.of(context)!.translate('upcoming')
                              : (userRole == 'organization' 
                                  ? AppLocalizations.of(context)!.translate('past')
                                  : AppLocalizations.of(context)!.translate('attended')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
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
                  
                  // Date
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
                  
                  // Location
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
                  
                  // Attendees
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${event.attendeesCount} ${AppLocalizations.of(context)!.translate('people_going')}',
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

  Widget _buildTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildCalendarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        6,
        (index) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E6F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ✅ FIXED TYPO: StrokeCap (was StroceCap)
class ClockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Draw clock face arc
    final arcPaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round; // ✅ FIXED

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14 / 2,
      3.14 * 1.5,
      false,
      arcPaint,
    );

    // Draw hour hand
    final hourPaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round; // ✅ FIXED

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius * 0.5),
      hourPaint,
    );

    // Draw minute hand
    final minutePaint = Paint()
      ..color = const Color(0xFF42A5F5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round; // ✅ FIXED

    canvas.drawLine(
      center,
      Offset(center.dx + radius * 0.6, center.dy),
      minutePaint,
    );

    // Draw center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF2C3E6F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}