
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/favorites/favorites_cubit.dart';
import '../bloc/favorites/favorites_state.dart';
import '../models/event.dart';

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

  void _toggleShareDialog() {
    setState(() {
      _showShareDialog = !_showShareDialog;
    });
  }

  void _shareEvent(String platform) {
    final eventText = 'Check out this event: ${widget.event.title} on ${widget.event.date} at ${widget.event.location}';

    switch (platform) {
      case 'whatsapp':
      case 'facebook':
      case 'messenger':
      case 'twitter':
      case 'instagram':
      case 'skype':
      case 'copy':
        Share.share(eventText);
        break;
    }

    _toggleShareDialog();
  }

  @override
  Widget build(BuildContext context) {
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
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Event Details',
                          style: TextStyle(
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
                        // Gradient overlay
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
                        // Music icon
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
                            // Profile images
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
                              '+${widget.event.attendeesCount} Going',
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
                              child: const Text(
                                'Follow',
                                style: TextStyle(
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
                        const Text(
                          'About Event',
                          style: TextStyle(
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
                              child: const Text(
                                'Follow',
                                style: TextStyle(
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
                        const Text(
                          'Read More',
                          style: TextStyle(
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
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Registration feature coming soon')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE85D75),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Register your seat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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

          // Share button (floating) with favorite functionality
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
                      onPressed: () {
                        context.read<FavoritesCubit>().toggleFavorite(widget.event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFavorite ? 'Removed from favorites' : 'Added to favorites'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
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

          // Share Dialog Overlay
          if (_showShareDialog)
            GestureDetector(
              onTap: _toggleShareDialog,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping dialog
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
                          const Text(
                            'Share with friends',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Share icons - Row 1
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildShareIcon(
                                icon: Icons.copy,
                                color: Colors.grey[300]!,
                                onTap: () => _shareEvent('copy'),
                              ),
                              _buildShareIcon(
                                icon: Icons.message,
                                color: const Color(0xFF25D366),
                                onTap: () => _shareEvent('whatsapp'),
                              ),
                              _buildShareIcon(
                                icon: Icons.facebook,
                                color: const Color(0xFF1877F2),
                                onTap: () => _shareEvent('facebook'),
                              ),
                              _buildShareIcon(
                                icon: Icons.messenger,
                                color: const Color(0xFF0084FF),
                                onTap: () => _shareEvent('messenger'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Share icons - Row 2
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildShareIcon(
                                icon: Icons.alternate_email,
                                color: const Color(0xFF1DA1F2),
                                onTap: () => _shareEvent('twitter'),
                              ),
                              _buildShareIcon(
                                icon: Icons.camera_alt,
                                color: const Color(0xFFE4405F),
                                onTap: () => _shareEvent('instagram'),
                              ),
                              _buildShareIcon(
                                icon: Icons.video_call,
                                color: const Color(0xFF00AFF0),
                                onTap: () => _shareEvent('skype'),
                              ),
                              _buildShareIcon(
                                icon: Icons.share,
                                color: const Color(0xFF34C759),
                                onTap: () => _shareEvent('more'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Cancel button
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
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
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
  }

  Widget _buildShareIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}