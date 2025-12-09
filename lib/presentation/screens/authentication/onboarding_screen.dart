import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '/../../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations_ar.dart';
import '../../l10n/app_localizations_en.dart';
import '../../l10n/app_localizations_fr.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../../l10n/app_localizations.dart';
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ WRAPPED with BlocBuilder
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _buildPhotoGrid(),
                        ),
                      ),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              // ✅ TRANSLATED
                              Text(
                                context.tr('find_nearby'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                context.tr('event_here'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              // ✅ TRANSLATED
                              Text(
                                context.tr('onboarding_subtitle'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildIndicator(true),
                                  const SizedBox(width: 8),
                                  _buildIndicator(false),
                                  const SizedBox(width: 8),
                                  _buildIndicator(false),
                                ],
                              ),
                              const SizedBox(height: 30),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade400,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  // ✅ TRANSLATED
                                  child: Text(
                                    context.tr('next'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                // ✅ TRANSLATED
                                child: Text(
                                  context.tr('skip_signup'),
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildImageCard(
                  'assets/images/event1.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _buildImageCard(
                  'assets/images/event2.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: _buildImageCard(
                  'assets/images/event3.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 3,
                child: _buildImageCard(
                  'assets/images/event4.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildImageCard(
                  'assets/images/event5.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: _buildImageCard(
                  'assets/images/event6.jpg',
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(String assetPath, {BorderRadius? borderRadius}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        color: Colors.grey[300],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      width: isActive ? 40 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.grey.shade600 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
