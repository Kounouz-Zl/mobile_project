import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '/../presentation/l10n/app_localizations.dart';
import '/../services/api_service.dart';
import '/../data/models/event.dart';
import '../events/event_details_screen.dart';

class OrganizationInfoScreen extends StatefulWidget {
  final String organizationId;

  const OrganizationInfoScreen({Key? key, required this.organizationId}) : super(key: key);

  @override
  State<OrganizationInfoScreen> createState() => _OrganizationInfoScreenState();
}

class _OrganizationInfoScreenState extends State<OrganizationInfoScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? profile;
  List<Event> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizationInfo();
  }

  Future<void> _loadOrganizationInfo() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      print('📥 Fetching organization profile for ID: ${widget.organizationId}');
      final response = await _apiService.get('/organizations/${widget.organizationId}/profile');
      
      print('✅ Organization profile fetched: ${response.data}');
      
      if (mounted) {
        setState(() {
          profile = response.data['profile'] as Map<String, dynamic>;
          events = (response.data['events'] as List? ?? [])
              .map((e) => Event.fromJson(e as Map<String, dynamic>))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading organization info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
      }
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
              context.tr('organization_profile'),
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
              : profile == null
                  ? Center(child: Text(context.tr('organization_not_found')))
                  : RefreshIndicator(
                      onRefresh: _loadOrganizationInfo,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF8B5CF6),
                                    const Color(0xFF6D28D9),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Profile Picture
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: profile!['profile_photo_url'] != null
                                        ? NetworkImage(profile!['profile_photo_url'] as String)
                                        : null,
                                    child: profile!['profile_photo_url'] == null
                                        ? const Icon(Icons.business, size: 50, color: Color(0xFF8B5CF6))
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  // Organization Name
                                  Text(
                                    profile!['name'] as String? ?? profile!['username'] as String? ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            // Profile Details
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Bio
                                  if (profile!['bio'] != null && (profile!['bio'] as String).isNotEmpty) ...[
                                    Text(
                                      context.tr('about'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      profile!['bio'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                  // Field
                                  if (profile!['field'] != null && (profile!['field'] as String).isNotEmpty) ...[
                                    _buildInfoRow(Icons.category, context.tr('field'), profile!['field'] as String),
                                    const SizedBox(height: 12),
                                  ],
                                  // Location
                                  if (profile!['location'] != null && (profile!['location'] as String).isNotEmpty) ...[
                                    _buildInfoRow(Icons.location_on, context.tr('location'), profile!['location'] as String),
                                    const SizedBox(height: 20),
                                  ],
                                  // Events Section
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        context.tr('events'),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${events.length} ${context.tr('events')}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Events List
                                  if (events.isEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(40),
                                        child: Column(
                                          children: [
                                            Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
                                            const SizedBox(height: 16),
                                            Text(
                                              context.tr('no_events_yet'),
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ...events.map((event) => _buildEventCard(event)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8B5CF6)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Event Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  event.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.event, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

