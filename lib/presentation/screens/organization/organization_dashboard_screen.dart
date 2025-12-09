// screens/organization_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/event.dart';
import '/../services/email_service.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  final Event? event; // Optional - if null, show all events

  const OrganizationDashboardScreen({Key? key, this.event}) : super(key: key);

  @override
  State<OrganizationDashboardScreen> createState() => _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState extends State<OrganizationDashboardScreen> {
  List<Event> myEvents = [];
  Map<String, int> eventRegistrations = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      final db = DatabaseHelper.instance;
      
      // If specific event provided, only load that one
      if (widget.event != null) {
        myEvents = [widget.event!];
      } else {
        // Load all events created by user
        myEvents = await db.getUserCreatedEvents(userState.user.id);
      }
      
      Map<String, int> registrations = {};
      for (var event in myEvents) {
        final regs = await db.getEventRegistrations(event.id);
        registrations[event.id] = regs.length;
      }
      
      setState(() {
        eventRegistrations = registrations;
        isLoading = false;
      });
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_event')),
        content: Text(context.tr('are_you_sure_delete_event').replaceAll('{title}', event.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = DatabaseHelper.instance;
      await db.deleteEvent(event.id);
      
      // If viewing single event, go back
      if (widget.event != null) {
        Navigator.pop(context);
      } else {
        _loadData();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('event_deleted_successfully')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showRegistrations(Event event) async {
    final db = DatabaseHelper.instance;
    final registrations = await db.getEventRegistrations(event.id);
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('registrations_for_event').replaceAll('{title}', event.title),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('people_registered').replaceAll('{count}', '${registrations.length}'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: registrations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('no_registrations_yet'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: registrations.length,
                      itemBuilder: (context, index) {
                        final reg = registrations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF8B5CF6),
                              child: Text(
                                reg['userName'].toString()[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              reg['userName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                context.tr('registered_at').replaceAll('{date}', _formatDate(reg['registeredAt'] as String)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('reason_for_joining'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        reg['reason'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                              Row(
  children: [
    Expanded(
      child: ElevatedButton.icon(
        onPressed: () async {
          // ✅ UPDATED: Approve with email notification
          try {
            final db = DatabaseHelper.instance;
            
            // Update status in database
            await db.updateRegistrationStatus(
              event.id,
              reg['userId'] as String,
              'approved',
            );
            
            // Get user email
            final userEmail = reg['userEmail'] as String;
            
            // Send approval email
            await EmailService.instance.sendRegistrationApprovalEmail(
              userEmail,
              reg['userName'] as String,
              event.title,
              event.date,
              event.location,
            );
            
            if (mounted) {
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr('user_approved').replaceAll('{name}', reg['userName'])
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              _loadData(); // Refresh data
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error approving registration: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.check, size: 18),
        label: Text(context.tr('approve')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: OutlinedButton.icon(
        onPressed: () async {
          // ✅ UPDATED: Reject with email notification
          try {
            final db = DatabaseHelper.instance;
            
            // Update status in database
            await db.updateRegistrationStatus(
              event.id,
              reg['userId'] as String,
              'rejected',
            );
            
            // Get user email
            final userEmail = reg['userEmail'] as String;
            
            // Send rejection email
            await EmailService.instance.sendRegistrationRejectionEmail(
              userEmail,
              reg['userName'] as String,
              event.title,
            );
            
            if (mounted) {
              Navigator.pop(context); // Close bottom sheet
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr('user_rejected').replaceAll('{name}', reg['userName'])
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
              _loadData(); // Refresh data
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error rejecting registration: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.close, size: 18),
        label: Text(context.tr('reject')),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    ),
  ],
),

                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return context.tr('minutes_ago').replaceAll('{count}', '${diff.inMinutes}');
        }
        return context.tr('hours_ago').replaceAll('{count}', '${diff.inHours}');
      } else if (diff.inDays == 1) {
        return context.tr('yesterday');
      } else if (diff.inDays < 7) {
        return context.tr('days_ago').replaceAll('{count}', '${diff.inDays}');
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
              widget.event != null ? context.tr('event_dashboard') : context.tr('my_events_dashboard'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : myEvents.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myEvents.length,
                        itemBuilder: (context, index) {
                          final event = myEvents[index];
                          final registrations = eventRegistrations[event.id] ?? 0;
                          
                          return _buildEventCard(event, registrations);
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
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.tr('no_events_created'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('create_your_first_event'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event, int registrations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEvent(event),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Clickable registrations card
            InkWell(
              onTap: () => _showRegistrations(event),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('registrations_count').replaceAll('{count}', '$registrations'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            context.tr('tap_to_view_details'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(event.date),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(event.location)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}