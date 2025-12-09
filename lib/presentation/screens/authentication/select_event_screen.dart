import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../logic/cubits/categories/categories_cubit.dart';
import '/../logic/cubits/categories/categories_state.dart';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_screen.dart';


class SelectEventScreen extends StatefulWidget {
  final String username;

  const SelectEventScreen({super.key, required this.username});

  @override
  State<SelectEventScreen> createState() => _SelectEventScreenState();
}

class _SelectEventScreenState extends State<SelectEventScreen> {
  final List<Map<String, dynamic>> events = [
    {'icon': '💼', 'label': 'Business'},
  
    {'icon': '🎉', 'label': 'Community'},
    {'icon': '🎤', 'label': 'Music & Entertainment'},
    {'icon': '🏥', 'label': 'Health'},
    {'icon': '🍔', 'label': 'Food & drink'},
    {'icon': '👨‍👩‍👧', 'label': 'Family & Education'},
    {'icon': '⚽', 'label': 'Sport'},
    {'icon': '👠', 'label': 'Fashion'},
    {'icon': '🎬', 'label': 'Film & Media'},
    {'icon': '🏠', 'label': 'Home & Lifestyle'},
    {'icon': '🎨', 'label': 'Design'},
    {'icon': '🎮', 'label': 'Gaming'},
    {'icon': '🔬', 'label': 'Science & Tech'},
    {'icon': '🎓', 'label': 'School & Education'},
    {'icon': '🎊', 'label': 'Holiday'},
    {'icon': '✈️', 'label': 'Travel'},
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F2FF),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Title
                  Text(
                    context.tr('choose_your_favorite_event'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('get_personalized_event_recommendation'),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  // Event categories
                  Expanded(
                    child: BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        return SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: events.map((event) {
                              final isSelected = context.read<CategoriesCubit>().isSelected(event['label']);

                              return GestureDetector(
                                onTap: () {
                                  context.read<CategoriesCubit>().toggleCategory(event['label']);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        event['icon'],
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        event['label'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Finish button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final selectedCategories = context.read<CategoriesCubit>().state.selectedCategories;

                        try {
                          await context.read<UserCubit>().updateCategories(selectedCategories.toList());

                          // Navigate to HomeScreen and remove all previous screens
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (route) => false,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('failed_to_save_categories').replaceAll('{error}', e.toString()))),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9966),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.tr('finish'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}