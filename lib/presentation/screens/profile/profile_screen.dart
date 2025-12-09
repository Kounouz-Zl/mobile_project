// screens/profile_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/favorites/favorites_cubit.dart';
import '/../data/databases/database_helper.dart';
import '/../data/models/user_model.dart';
import '/../presentation/screens/events/events_screen.dart';
import '/../presentation/screens/favorites/favourites_screan.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '/../logic/cubits/language/language_cubit.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  int eventsCount = 0;
  int favoritesCount = 0;
  bool isLoadingStats = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _loadUserStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    final userState = context.read<UserCubit>().state;
    if (userState is UserLoaded) {
      final db = DatabaseHelper.instance;
      
      try {
        final joinedEvents = await db.getUserJoinedEvents(userState.user.id);
        final createdEvents = await db.getUserCreatedEvents(userState.user.id);
        
        final allEventIds = <String>{
          ...joinedEvents.map((e) => e.id),
          ...createdEvents.map((e) => e.id),
        };
        
        final favorites = await db.getUserFavorites(userState.user.id);
        
        setState(() {
          eventsCount = allEventIds.length;
          favoritesCount = favorites.length;
          isLoadingStats = false;
        });
      } catch (e) {
        print('Error loading stats: $e');
        setState(() {
          isLoadingStats = false;
        });
      }
    }
  }

  Widget _buildProfileImage(UserModel user) {
    if (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty) {
      if (user.profilePhotoUrl!.startsWith('/') || 
          user.profilePhotoUrl!.startsWith('file://') ||
          !user.profilePhotoUrl!.startsWith('http')) {
        final file = File(user.profilePhotoUrl!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading profile image from file: $error');
              return _buildDefaultAvatar();
            },
          );
        }
      } else {
        return Image.network(
          user.profilePhotoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading profile image from network: $error');
            return _buildDefaultAvatar();
          },
        );
      }
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade100, Colors.purple.shade200],
        ),
      ),
      child: const Icon(Icons.person, size: 60, color: Color(0xFF8B5CF6)),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 30)),
              title: const Text('English'),
              onTap: () async {
                await context.read<LanguageCubit>().changeLanguage('en');
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Text('🇫🇷', style: TextStyle(fontSize: 30)),
              title: const Text('Français'),
              onTap: () async {
                await context.read<LanguageCubit>().changeLanguage('fr');
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 30)),
              title: const Text('العربية'),
              onTap: () async {
                await context.read<LanguageCubit>().changeLanguage('ar');
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(context.tr('logout')),
          ],
        ),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel'), style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              try {
                final db = DatabaseHelper.instance;
                await db.logout();
                
                if (context.mounted) {
                  context.read<UserCubit>().logout();
                }
                
                if (context.mounted) {
                  await context.read<FavoritesCubit>().clearFavorites();
                }
                
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
                
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserLoaded) {
            final user = state.user;
            
            return FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300, // ✅ INCREASED HEIGHT
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF8B5CF6),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF8B5CF6),
                              const Color(0xFF6D28D9),
                              Colors.purple.shade900,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -50,
                              right: -50,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -30,
                              left: -30,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                            ),
                            // ✅ FIXED: Added SafeArea and better spacing
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 60),
                                    Hero(
                                      tag: 'profile_pic',
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 120, // ✅ SLIGHTLY REDUCED SIZE
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.orange.shade300,
                                                  Colors.orange.shade600,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.3),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: ClipOval(
                                                child: _buildProfileImage(user),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () async {
                                                final ImagePicker picker = ImagePicker();
                                                final XFile? image = await picker.pickImage(
                                                  source: ImageSource.gallery,
                                                  maxWidth: 500,
                                                  maxHeight: 500,
                                                );
                                                
                                                if (image != null) {
                                                  await context.read<UserCubit>().updateProfilePhoto(image.path);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(context.tr('profile_photo_updated')),
                                                      backgroundColor: Colors.green,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.orange.shade400,
                                                      Colors.orange.shade600,
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 3),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // ✅ FIXED: Username with edit button - better layout
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            user.username,
                                            style: const TextStyle(
                                              fontSize: 24, // ✅ REDUCED FONT SIZE
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _showEditUsernameDialog(context, user.username),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // ✅ FIXED: Email with better constraints
                                    Container(
                                      constraints: const BoxConstraints(maxWidth: 300),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              user.email,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: Colors.greenAccent,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.event,
                                  title: context.tr('events'),
                                  value: isLoadingStats ? '...' : '$eventsCount',
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const EventsScreen(),
                                      ),
                                    ).then((_) => _loadUserStats());
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.favorite,
                                  title: context.tr('favorites'),
                                  value: isLoadingStats ? '...' : '$favoritesCount',
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const FavoritesScreen(),
                                      ),
                                    ).then((_) => _loadUserStats());
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          
                          // Interests section
                          if (user.selectedCategories.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.favorite, color: Color(0xFF8B5CF6), size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('my_interests'),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _showEditCategoriesDialog(context, user.selectedCategories);
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text(context.tr('edit')),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.selectedCategories.map((category) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade100, Colors.orange.shade50],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.orange.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('🎯', style: TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 28),
                          ],
                          
                          // Settings section
                          Row(
                            children: [
                              const Icon(Icons.settings, color: Color(0xFF8B5CF6), size: 24),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('account_settings'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSettingsItem(
                            icon: Icons.person_outline,
                            title: context.tr('edit_profile'),
                            subtitle: context.tr('edit_username'),
                            color: Colors.blue,
                            onTap: () => _showEditUsernameDialog(context, user.username),
                          ),
                          _buildSettingsItem(
                            icon: Icons.email_outlined,
                            title: context.tr('email_address'),
                            subtitle: user.email,
                            color: Colors.green,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified, color: Colors.green, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.tr('verified'),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildSettingsItem(
                            icon: Icons.category_outlined,
                            title: context.tr('interests'),
                            subtitle: '${user.selectedCategories.length} ${context.tr('interests').toLowerCase()}',
                            color: Colors.orange,
                            onTap: () => _showEditCategoriesDialog(context, user.selectedCategories),
                          ),
                          _buildSettingsItem(
                            icon: Icons.language,
                            title: context.tr('language'),
                            subtitle: context.tr('change_language'),
                            color: Colors.purple,
                            onTap: () => _showLanguageDialog(context),
                          ),
                          const SizedBox(height: 20),
                          
                          // ✅ FIXED: Logout button with proper constraints
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Colors.red.shade400, Colors.red.shade600],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showLogoutDialog(context),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 56,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Text(
                                        context.tr('logout'),
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
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text(context.tr('error')));
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey) : null),
        onTap: onTap,
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('edit_username')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.tr('enter_username'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                try {
                  await context.read<UserCubit>().updateUsername(controller.text.trim());
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('username_updated')),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showEditCategoriesDialog(BuildContext context, List<String> currentCategories) {
    final List<String> allCategories = [
      'Business', 'Community', 'Music & Entertainment', 'Health', 'Food & drink',
      'Family & Education', 'Sport', 'Fashion', 'Film & Media', 'Home & Lifestyle',
      'Design', 'Gaming', 'Science & Tech', 'School & Education', 'Holiday', 'Travel',
    ];
    List<String> selectedCategories = List.from(currentCategories);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(context.tr('edit_interests')),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final category = allCategories[index];
                  final isSelected = selectedCategories.contains(category);
                  return CheckboxListTile(
                    title: Text(category),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      });
                    },
                    activeColor: const Color(0xFF8B5CF6),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr('cancel')),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<UserCubit>().updateCategories(selectedCategories);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('interests_updated')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('save')),
              ),
            ],
          );
        },
      ),
    );
  }
}