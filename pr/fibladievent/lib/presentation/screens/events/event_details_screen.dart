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
import '/../services/api_service.dart';
import '/../data/models/event.dart';
import 'event_registration_screen.dart';
import 'add_event_screen.dart';
import '../organization/organization_dashboard_screen.dart';
import '../organization/organization_info_screen.dart';
import 'dart:io';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with WidgetsBindingObserver {
  bool _showShareDialog = false;
  bool _isJoined = false;
  bool _isLoading = true;
  int _currentAttendeesCount = 0;
  bool _isOwnEvent = false;
  String? _registrationStatus; // null, 'pending', 'approved', 'rejected'
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //_currentAttendeesCount = widget.event.attendeesCount;
    _currentAttendeesCount = 0; // Start at 0
    _checkEventOwnership();
    _checkIfJoined();
    _loadAttendanceCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh status when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _checkIfJoined();
      _loadAttendanceCount();
    }
  }

  Widget _buildEventImage() {
    final imageUrl = widget.event.imageUrl;

    print('🖼️ Building event image:');
    print('   - Image URL: $imageUrl');
    print('   - Is empty: ${imageUrl.isEmpty}');
    print('   - Is placeholder: ${imageUrl.contains('placeholder')}');

    // Check if it's a local file path
    if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Error loading file image: $error');
            return _buildPlaceholderImage();
          },
        );
      } else {
        print('❌ File does not exist: $imageUrl');
      }
    }

    // Otherwise, treat as network URL
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 250,
          color: Colors.grey[300],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF8B5CF6),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading network image: $error');
        print('   - URL was: $imageUrl');
        return _buildPlaceholderImage();
      },
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 60, color: Colors.grey[500]),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Check if this is the organizer's own event
  Future<void> _checkEventOwnership() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      // Check if the user created this event
      print('👤 Checking event ownership:');
      print('   - Event createdBy: ${widget.event.createdBy}');
      print('   - Current user ID: ${userState.user.id}');
      
      setState(() {
        _isOwnEvent = widget.event.createdBy == userState.user.id;
        print('   - Is own event: $_isOwnEvent');
      });
    }
  }

  Future<void> _checkIfJoined() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      try {
        final response = await _apiService
            .get('/events/${widget.event.id}/registration-status');

        final status = response.data['status'] as String?;

        if (mounted) {
          setState(() {
            _registrationStatus = status;
            _isJoined = status == 'approved';
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _registrationStatus = null;
            _isJoined = false;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAttendanceCount() async {
    try {
      final response = await _apiService
          .get('/events/${widget.event.id}/approved-count'); // ✅
      final count = response.data['count'] ?? 0;

      if (mounted) {
        setState(() {
          _currentAttendeesCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAttendeesCount = 0;
        });
      }
    }
  }

  Future<void> _handleJoinEvent() async {
    // If this is the organizer's own event, navigate to dashboard
    if (_isOwnEvent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OrganizationDashboardScreen(event: widget.event),
        ),
      );
      return;
    }

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

    // Handle different registration states
    if (_registrationStatus == 'pending') {
      // Show cancel dialog
      _cancelRegistration();
    } else if (_registrationStatus == 'approved' || _isJoined) {
      _leaveEvent();
    } else if (_registrationStatus == 'rejected') {
      // Can register again after rejection
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventRegistrationScreen(event: widget.event),
        ),
      );

      if (result == true) {
        _checkIfJoined();
        _loadAttendanceCount();
      }
    } else {
      // No registration yet - show registration screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventRegistrationScreen(event: widget.event),
        ),
      );

      if (result == true) {
        _checkIfJoined();
        _loadAttendanceCount();
      }
    }
  }

  Future<void> _cancelRegistration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('cancel_registration')),
        content: Text(context.tr('are_you_sure_cancel_registration')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('no_keep_it')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(context.tr('yes_cancel')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.post('/events/${widget.event.id}/registrations/cancel');

      setState(() {
        _registrationStatus = null;
        _isJoined = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('registration_cancelled')),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  // ✅ REPLACE the _leaveEvent method
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
      await _apiService.post('/events/${widget.event.id}/leave');

      setState(() {
        _isJoined = false;
      });

      _loadAttendanceCount(); // ✅ Reload count after leaving

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
    final eventText =
        '${context.tr('check_out_this_event')}: ${widget.event.title} ${context.tr('on')} ${widget.event.date} ${context.tr('at')} ${widget.event.location}';
    Share.share(eventText);
    _toggleShareDialog();
  }

  @override
  Widget build(BuildContext context) {
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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                            Text(
                              context.tr('event_details'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Dashboard button for organizers viewing their own event
                                if (_isOwnEvent)
                                  IconButton(
                                    icon: const Icon(Icons.dashboard,
                                        color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OrganizationDashboardScreen(
                                            event: widget.event,
                                          ),
                                        ),
                                      );
                                    },
                                    tooltip: context.tr('view_dashboard'),
                                  ),
                                // Edit button for organizers who own the event
                                if (_isOwnEvent)
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddEventScreen(
                                            eventToEdit: widget.event,
                                          ),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        // Refresh event data
                                        _checkIfJoined();
                                        _loadAttendanceCount();
                                      }
                                    },
                                    tooltip: context.tr('edit_event'),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.refresh,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() => _isLoading = true);
                                    _checkIfJoined();
                                    _loadAttendanceCount();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ✅ FIX 5: Event Image with proper loading
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // The actual image
                              _buildEventImage(),

                              // Gradient overlay
                              Container(
                                height: 250,
                                decoration: BoxDecoration(
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

                              // Category badge
                              if (widget.event.category != null)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.category,
                                            color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.event.category!,
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
                              context.tr('about event'),
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
                                Icon(Icons.location_on,
                                    color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                Icon(Icons.calendar_today,
                                    color: Colors.grey[600], size: 20),
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

                            // Organization Info
                            InkWell(
                              onTap: () {
                                final orgId = widget.event.createdBy;
                                print('🔗 Navigating to organization profile:');
                                print('   - Organization ID: $orgId');
                                print('   - Event ID: ${widget.event.id}');
                                print('   - Event created_by: ${widget.event.createdBy}');
                                
                                if (orgId == null || orgId.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(context
                                          .tr('organization_not_found')),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrganizationInfoScreen(
                                            organizationId: orgId),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: widget.event
                                              .organizerImageUrl.isNotEmpty
                                          ? NetworkImage(
                                              widget.event.organizerImageUrl)
                                          : null,
                                      backgroundColor: Colors.grey[300],
                                      child:
                                          widget.event.organizerImageUrl.isEmpty
                                              ? const Icon(Icons.business,
                                                  color: Colors.grey)
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.event.organizerName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            context.tr('tap_to_view_profile'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Attendees count
                            Text(
                              '$_currentAttendeesCount ${context.tr('attendees')}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
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

                            const SizedBox(height: 24),

                            // Register Button with Status
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleJoinEvent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _getButtonColor(),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _getButtonIcon(),
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _getButtonText(context),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
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
                        final isFavorite =
                            state.favoriteEventIds.contains(widget.event.id);
                        return FloatingActionButton(
                          heroTag: 'favorite',
                          onPressed: () async {
                            await context
                                .read<FavoritesCubit>()
                                .toggleFavorite(widget.event.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFavorite
                                      ? context.tr('removed from favorites')
                                      : context.tr('added to favorites')),
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
                                context.tr('share with friends'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildShareIcon(Icons.copy, Colors.grey[300]!,
                                      () => _shareEvent('copy')),
                                  _buildShareIcon(
                                      Icons.message,
                                      const Color(0xFF25D366),
                                      () => _shareEvent('whatsapp')),
                                  _buildShareIcon(
                                      Icons.facebook,
                                      const Color(0xFF1877F2),
                                      () => _shareEvent('facebook')),
                                  _buildShareIcon(
                                      Icons.messenger,
                                      const Color(0xFF0084FF),
                                      () => _shareEvent('messenger')),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildShareIcon(
                                      Icons.alternate_email,
                                      const Color(0xFF1DA1F2),
                                      () => _shareEvent('twitter')),
                                  _buildShareIcon(
                                      Icons.camera_alt,
                                      const Color(0xFFE4405F),
                                      () => _shareEvent('instagram')),
                                  _buildShareIcon(
                                      Icons.video_call,
                                      const Color(0xFF00AFF0),
                                      () => _shareEvent('skype')),
                                  _buildShareIcon(
                                      Icons.share,
                                      const Color(0xFF34C759),
                                      () => _shareEvent('more')),
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

  Color _getButtonColor() {
    if (_isOwnEvent) {
      return const Color(0xFF8B5CF6); // Purple for organizer
    }
    if (_registrationStatus == 'pending') {
      return Colors.orange;
    } else if (_registrationStatus == 'approved' || _isJoined) {
      return Colors.green;
    } else if (_registrationStatus == 'rejected') {
      return Colors.grey;
    }
    return const Color(0xFFE85D75);
  }

  IconData _getButtonIcon() {
    if (_isOwnEvent) {
      return Icons.people; // People icon for organizer
    }
    if (_registrationStatus == 'pending') {
      return Icons.pending;
    } else if (_registrationStatus == 'approved' || _isJoined) {
      return Icons.check_circle;
    } else if (_registrationStatus == 'rejected') {
      return Icons.cancel;
    }
    return Icons.app_registration;
  }

  String _getButtonText(BuildContext context) {
    if (_isOwnEvent) {
      return context.tr('see_registered_people');
    }
    if (_registrationStatus == 'pending') {
      return context.tr('pending_tap_to_cancel');
    } else if (_registrationStatus == 'approved' || _isJoined) {
      return context.tr('accepted_tap_to_leave');
    } else if (_registrationStatus == 'rejected') {
      return context.tr('rejected_tap_to_register_again');
    }
    return context.tr('register_your_seat');
  }
}
