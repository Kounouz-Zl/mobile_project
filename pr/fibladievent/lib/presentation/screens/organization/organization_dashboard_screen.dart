// screens/organization_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../services/api_service.dart';
import '/../data/models/event.dart';

class OrganizationDashboardScreen extends StatefulWidget {
  final Event? event; // Optional - if null, show all events

  const OrganizationDashboardScreen({Key? key, this.event}) : super(key: key);

  @override
  State<OrganizationDashboardScreen> createState() =>
      _OrganizationDashboardScreenState();
}

class _OrganizationDashboardScreenState
    extends State<OrganizationDashboardScreen> {
  final ApiService _apiService = ApiService();
  List<Event> myEvents = [];
  Map<String, int> eventRegistrations = {};
  Map<String, int> pendingRegistrations = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // If specific event provided, only load that one
      if (widget.event != null) {
        myEvents = [widget.event!];
      } else {
        // Load all events created by user
        final response = await _apiService.get('/events/my-events');
        myEvents = (response.data as List)
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      Map<String, int> registrations = {};
      Map<String, int> pendingRegs = {};
      for (var event in myEvents) {
        try {
          final regsResponse =
              await _apiService.get('/events/${event.id}/registrations');
          
          // Check for errors
          if (regsResponse.data is Map && (regsResponse.data as Map).containsKey('error')) {
            print('⚠️ Error loading registrations for ${event.id}: ${(regsResponse.data as Map)['error']}');
            registrations[event.id] = 0;
            pendingRegs[event.id] = 0;
            continue;
          }
          
          // Parse registrations list
          List regsList;
          if (regsResponse.data is List) {
            regsList = regsResponse.data as List;
          } else if (regsResponse.data is Map && (regsResponse.data as Map).containsKey('registrations')) {
            regsList = (regsResponse.data as Map)['registrations'] as List? ?? [];
          } else {
            regsList = [];
          }
          
          registrations[event.id] = regsList.length;
          // Count pending registrations
          final pending = regsList.where((r) => r is Map && (r['status'] == 'pending')).length;
          pendingRegs[event.id] = pending;
        } catch (e) {
          print('❌ Error loading registrations for ${event.id}: $e');
          registrations[event.id] = 0;
          pendingRegs[event.id] = 0;
        }
      }

      if (mounted) {
        setState(() {
          eventRegistrations = registrations;
          pendingRegistrations = pendingRegs;
          isLoading = false;
        });
      }
      
      // Store pending registrations in the state
      // (We'll add this to the widget state)
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_event')),
        content: Text(context
            .tr('are_you_sure_delete_event')
            .replaceAll('{title}', event.title)),
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
      try {
        await _apiService.delete('/events/${event.id}');

        // If viewing single event, go back
        if (widget.event != null) {
          if (mounted) Navigator.pop(context);
        } else {
          await _loadData();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('event_deleted_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error deleting event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('error_deleting_event')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }



  void _showRegistrations(Event event) async {
    try {
      final response =
          await _apiService.get('/events/${event.id}/registrations');
      
      print('🔵 Registrations response: ${response.statusCode}');
      print('🔵 Response data type: ${response.data.runtimeType}');
      print('🔵 Response data: ${response.data}');
      
      // Check for errors first
      if (response.data is Map && response.data.containsKey('error')) {
        throw Exception(response.data['error']);
      }
      
      // Backend returns a list directly
      List registrations;
      if (response.data is List) {
        registrations = response.data as List;
      } else if (response.data is Map && response.data.containsKey('registrations')) {
        registrations = response.data['registrations'] as List? ?? [];
      } else {
        registrations = [];
      }

      print('✅ Parsed ${registrations.length} registrations');

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
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
                      context
                          .tr('registrations_for_event')
                          .replaceAll('{title}', event.title),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context
                          .tr('people_registered')
                          .replaceAll('{count}', '${registrations.length}'),
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
                            Icon(Icons.people_outline,
                                size: 80, color: Colors.grey[300]),
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
                          final reg = registrations[index] as Map<String, dynamic>;
                          final status = _getStatus(reg);
                          final userName = _getUserName(reg);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: status == 'approved'
                                    ? Colors.green
                                    : status == 'rejected'
                                        ? Colors.red
                                        : const Color(0xFF8B5CF6),
                                child: Text(
                                  userName.isNotEmpty
                                      ? userName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: status == 'approved'
                                          ? Colors.green.shade100
                                          : status == 'rejected'
                                              ? Colors.red.shade100
                                              : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'approved'
                                            ? Colors.green.shade700
                                            : status == 'rejected'
                                                ? Colors.red.shade700
                                                : Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child:                                     Text(
                                      _getRegistrationDate(reg),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('reason for joining'),
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
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          (reg['reason'] ?? 'No reason provided').toString(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[800],
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (status == 'pending') ...[
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () async {
                                                  try {
                                                    // Approve registration
                                                    final regId = reg['id']?.toString() ?? '';
                                                    if (regId.isEmpty) {
                                                      throw Exception('Registration ID is missing');
                                                    }
                                                    await _apiService.put(
                                                         '/events/${event.id}/registrations/$regId/approve',
                                                          data: {}
                                                             );
                                                       

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            context
                                                                .tr('user approved')
                                                                .replaceAll(
                                                                  '{name}',
                                                                  userName,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );

                                                      // Refresh the registrations list
                                                      Navigator.pop(context);
                                                      await _loadData();
                                                      // Reopen the registrations modal with updated data
                                                      _showRegistrations(event);
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(e
                                                              .toString()
                                                              .replaceAll(
                                                                  'Exception: ',
                                                                  '')),
                                                          backgroundColor:
                                                              Colors.red,
                                                          duration:
                                                              const Duration(
                                                                  seconds: 4),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.check,
                                                    size: 18),
                                                label:
                                                    Text(context.tr('approve')),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () async {
                                                  try {
                                                    // Reject registration
                                                    final regId = reg['id']?.toString() ?? '';
                                                    if (regId.isEmpty) {
                                                      throw Exception('Registration ID is missing');
                                                    }
                                                    await _apiService.put(
  '/events/${event.id}/registrations/$regId/reject',
  data: {}
);

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            context
                                                                .tr('user rejected')
                                                                .replaceAll(
                                                                  '{name}',
                                                                  userName,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                      );

                                                      // Refresh the registrations list
                                                      Navigator.pop(context);
                                                      await _loadData();
                                                      // Reopen the registrations modal with updated data
                                                      _showRegistrations(event);
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(e
                                                              .toString()
                                                              .replaceAll(
                                                                  'Exception: ',
                                                                  '')),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.close,
                                                    size: 18),
                                                label:
                                                    Text(context.tr('reject')),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                  side: const BorderSide(
                                                      color: Colors.red),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: status == 'approved'
                                                ? Colors.green.shade50
                                                : Colors.red.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: status == 'approved'
                                                  ? Colors.green.shade200
                                                  : Colors.red.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                status == 'approved'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: status == 'approved'
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  status == 'approved'
                                                      ? 'This registration has been approved'
                                                      : 'This registration has been rejected',
                                                  style: TextStyle(
                                                    color: status == 'approved'
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
    } catch (e, stackTrace) {
      print('❌ Error loading registrations: $e');
      print('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading registrations: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Helper function to safely get user name from registration
  String _getUserName(Map<String, dynamic> reg) {
    return (reg['userName'] ?? reg['user_name'] ?? 'Unknown').toString();
  }

  // Helper function to safely get status from registration
  String _getStatus(Map<String, dynamic> reg) {
    return (reg['status'] ?? 'pending').toString();
  }

  String _getRegistrationDate(Map<String, dynamic> reg) {
    // Try different possible timestamp field names
    String? dateStr;
    if (reg.containsKey('created_at') && reg['created_at'] != null) {
      dateStr = reg['created_at'].toString();
    } else if (reg.containsKey('registeredAt') && reg['registeredAt'] != null) {
      dateStr = reg['registeredAt'].toString();
    } else if (reg.containsKey('createdAt') && reg['createdAt'] != null) {
      dateStr = reg['createdAt'].toString();
    } else if (reg.containsKey('timestamp') && reg['timestamp'] != null) {
      dateStr = reg['timestamp'].toString();
    }
    
    if (dateStr != null && dateStr.isNotEmpty) {
      return context.tr('registered_at').replaceAll('{date}', _formatDate(dateStr));
    }
    
    // No timestamp available
    return context.tr('registered_recently');
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        if (diff.inHours == 0) {
          return context
              .tr('minutes_ago')
              .replaceAll('{count}', '${diff.inMinutes}');
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
              widget.event != null
                  ? context.tr('event_dashboard')
                  : context.tr('my_events_dashboard'),
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
                          final registrations =
                              eventRegistrations[event.id] ?? 0;
                          final pending =
                              pendingRegistrations[event.id] ?? 0;

                          return _buildEventCard(event, registrations, pending);
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

  Widget _buildEventCard(Event event, int registrations, int pending) {
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
                  color: pending > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pending > 0 ? Colors.orange.shade200 : Colors.green.shade200,
                    width: pending > 0 ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pending > 0 ? Colors.orange : Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        pending > 0 ? Icons.pending_actions : Icons.people,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context
                                    .tr('registrations_count')
                                    .replaceAll('{count}', '$registrations'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: pending > 0 ? Colors.orange.shade700 : Colors.green,
                                ),
                              ),
                              if (pending > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$pending ${context.tr('pending')}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            pending > 0 
                                ? context.tr('tap_to_review_pending')
                                : context.tr('tap_to_view_details'),
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
                      color: pending > 0 ? Colors.orange : Colors.green,
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
