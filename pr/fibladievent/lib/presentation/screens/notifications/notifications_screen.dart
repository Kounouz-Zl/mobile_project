import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../services/api_service.dart';
import '/../data/models/event.dart';
import '../events/event_details_screen.dart';
import '../organization/organization_dashboard_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await _apiService.get('/notifications/');
      if (mounted) {
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(response.data as List);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiService.put('/notifications/$notificationId/read', data: {});
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _apiService.delete('/notifications/$notificationId');
      await _loadNotifications();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _clearAll() async {
    try {
      await _apiService.delete('/notifications/all');
      await _loadNotifications();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return '${diff.inMinutes}m ago';
        }
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
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
              context.tr('notifications'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: _clearAll,
                  child: Text(
                    context.tr('clear_all'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index];
                          return _buildNotificationCard(notif);
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
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            context.tr('no_notifications'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('notifications_will_appear_here'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    // Handle both boolean and integer isRead values
    final isRead = notif['isRead'] == true || notif['isRead'] == 1;
    final type = notif['type'] as String;

    IconData icon;
    Color color;

    switch (type) {
      case 'approval':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejection':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'new_registration':
        icon = Icons.person_add;
        color = Colors.orange;
        break;
      case 'new_event':
        icon = Icons.event;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.blue;
    }

    return Dismissible(
      key: Key(notif['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(notif['id'].toString());
      },
      child: GestureDetector(
        onTap: () async {
          if (!isRead) {
            await _markAsRead(notif['id'].toString());
          }

          // Navigate to event if relatedId exists
          final relatedId = notif['relatedId'] ?? notif['related_id'];
          if (relatedId != null) {
            try {
              final response = await _apiService.get('/events/$relatedId');

              // Backend returns the event wrapped in an "event" field:
              // { "event": { ...actual event data... } }
              final data = response.data;
              final eventJson = data is Map<String, dynamic> && data['event'] is Map
                  ? Map<String, dynamic>.from(data['event'] as Map)
                  : Map<String, dynamic>.from(data as Map);

              if (mounted) {
                final event = Event.fromJson(eventJson);
                // For new_registration type, navigate to organization dashboard
                if (type == 'new_registration') {
                  // Import the organization dashboard screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrganizationDashboardScreen(event: event),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  );
                }
              }
            } catch (e) {
              print('Error fetching event: $e');
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRead ? Colors.grey.shade200 : color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              if (!isRead)
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif['title'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif['message'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate((notif['createdAt'] ??
                              notif['created_at'] ??
                              DateTime.now().toIso8601String())
                          .toString()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
