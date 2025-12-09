// screens/event_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '/../logic/cubits/favorites/favorites_cubit.dart';
import '/../logic/cubits/favorites/favorites_state.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/event.dart';
import 'event_registration_screen.dart';
import '../organization/organization_dashboard_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _showShareDialog = false;
  bool _isJoined = false;
  bool _isLoading = true;
  int _currentAttendeesCount = 0;
  bool _isOwnEvent = false;

  @override
  void initState() {
    super.initState();
    _currentAttendeesCount = widget.event.attendeesCount;
    _checkEventOwnership();
    _checkIfJoined();
  }

  // ✅ NEW: Check if this is the organizer's own event
  Future<void> _checkEventOwnership() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      // Check if the user created this event
      setState(() {
        _isOwnEvent = widget.event.createdBy == userState.user.id;
      });
      
      // If it's their own event and they're an organizer, redirect to dashboard
      if (_isOwnEvent && userState.user.role == 'organization') {
        Future.microtask(() {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrganizationDashboardScreen(event: widget.event),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _checkIfJoined() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      final db = DatabaseHelper.instance;
      final isJoined = await db.isUserJoinedEvent(
        widget.event.id,
        userState.user.id,
      );
      
      setState(() {
        _isJoined = isJoined;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleJoinEvent() async {
    final userState = context.read<UserCubit>().state;
    if (userState is! UserLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('please_login_to_join_events')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isJoined) {
      _leaveEvent();
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventRegistrationScreen(event: widget.event),
        ),
      );
      
      if (result == true) {
        _checkIfJoined();
        setState(() {
          _currentAttendeesCount++;
        });
      }
    }
  }

  Future<void> _leaveEvent() async {
    final userState = context.read<UserCubit>().state;
    if (userState is! UserLoaded) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('leave_event')),
        content: Text(context.tr('are_you_sure_leave_event')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(context.tr('leave')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      await db.leaveEvent(widget.event.id, userState.user.id);
      
      setState(() {
        _isJoined = false;
        _currentAttendeesCount = _currentAttendeesCount > 0 
            ? _currentAttendeesCount - 1 
            : 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('you_have_left_this_event')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleShareDialog() {
    setState(() {
      _showShareDialog = !_showShareDialog;
    });
  }

  void _shareEvent(String platform) {
    final eventText = '${context.tr('check_out_this_event')}: ${widget.event.title} ${context.tr('on')} ${widget.event.date} ${context.tr('at')} ${widget.event.location}';
    Share.share(eventText);
    _toggleShareDialog();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if it's their own event (will redirect)
    if (_isOwnEvent) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1B2E),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1B2E),
          body: Stack(
            children: [
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with back button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                            Text(
                              context.tr('event_details'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),

                      // Event Image
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(widget.event.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 16,
                              left: 16,
                              child: Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Event Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Attendees and Follow button
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 30,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.blue,
                                          child: const Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        left: 20,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.green,
                                          child: const Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                      ),
                                      Positioned(
                                        left: 40,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.orange,
                                          child: const Icon(Icons.person, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('going_count').replaceAll('{count}', '+$_currentAttendeesCount'),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    context.tr('follow'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Event Title
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // About Event
                            Text(
                              context.tr('about_event'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.event.location,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        widget.event.locationAddress,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Date
                            Row(
                              children: [
                                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.event.date,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Organizer
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(widget.event.organizerImageUrl),
                                  backgroundColor: Colors.grey[300],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.event.organizerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    context.tr('follow'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Description
                            Text(
                              widget.event.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Read More
                            Text(
                              context.tr('read_more'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleJoinEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isJoined 
                                      ? Colors.orange 
                                      : const Color(0xFFE85D75),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isJoined 
                                                ? Icons.check_circle 
                                                : Icons.app_registration,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isJoined 
                                                ? context.tr('joined_tap_to_leave')
                                                : context.tr('register_your_seat'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (!_isJoined) ...[
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                          ],
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),

              // Share button with favorite
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    BlocBuilder<FavoritesCubit, FavoritesState>(
                      builder: (context, state) {
                        final isFavorite = state.favoriteEventIds.contains(widget.event.id);
                        return FloatingActionButton(
                          heroTag: 'favorite',
                          onPressed: () async {
                            await context.read<FavoritesCubit>().toggleFavorite(widget.event.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFavorite ? context.tr('removed_from_favorites') : context.tr('added_to_favorites')),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          backgroundColor: Colors.white,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'share',
                      onPressed: _toggleShareDialog,
                      backgroundColor: const Color(0xFF8B5CF6),
                      child: const Icon(Icons.share, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Share Dialog
              if (_showShareDialog)
                GestureDetector(
                  onTap: _toggleShareDialog,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.tr('share_with_friends'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildShareIcon(Icons.copy, Colors.grey[300]!, () => _shareEvent('copy')),
                                  _buildShareIcon(Icons.message, const Color(0xFF25D366), () => _shareEvent('whatsapp')),
                                  _buildShareIcon(Icons.facebook, const Color(0xFF1877F2), () => _shareEvent('facebook')),
                                  _buildShareIcon(Icons.messenger, const Color(0xFF0084FF), () => _shareEvent('messenger')),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildShareIcon(Icons.alternate_email, const Color(0xFF1DA1F2), () => _shareEvent('twitter')),
                                  _buildShareIcon(Icons.camera_alt, const Color(0xFFE4405F), () => _shareEvent('instagram')),
                                  _buildShareIcon(Icons.video_call, const Color(0xFF00AFF0), () => _shareEvent('skype')),
                                  _buildShareIcon(Icons.share, const Color(0xFF34C759), () => _shareEvent('more')),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton(
                                  onPressed: _toggleShareDialog,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr('cancel'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}