// main.dart - FIXED VERSION WITH WORKING LOCALIZATION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/../presentation/screens/authentication/onboarding_screen.dart';
import '/../presentation/screens/home/home_screen.dart';
import '/../presentation/screens/authentication/login_screen.dart';
import 'logic/cubits/auth/auth_bloc.dart';
import 'logic/cubits/auth/auth_state.dart';
import 'logic/cubits/auth/auth_event.dart';
import 'logic/cubits/user/user_cubit.dart';
import 'logic/cubits/events/events_cubit.dart';
import 'logic/cubits/favorites/favorites_cubit.dart';
import 'logic/cubits/categories/categories_cubit.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/events_repository.dart';
import 'data/repositories/user_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '/presentation/l10n/app_localizations.dart';
import 'logic/cubits/language/language_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => EventsRepository()),
        RepositoryProvider(create: (_) => UserRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          /// LANGUAGE CUBIT - MUST BE FIRST
          BlocProvider(create: (_) => LanguageCubit()),

          /// AUTH BLOC
          BlocProvider(
            create: (context) {
              final bloc = AuthBloc(
                authRepository: context.read<AuthRepository>(),
              );

              /// Run auth check after first frame
              Future.microtask(() {
                bloc.add(const CheckAuthStatus());
              });

              return bloc;
            },
          ),

          /// USER CUBIT
          BlocProvider(
            create: (context) => UserCubit(),
          ),

          /// EVENTS CUBIT
          BlocProvider(
            create: (context) => EventsCubit(
              eventsRepository: context.read<EventsRepository>(),
            )..fetchEvents(),
          ),

          /// FAVORITES CUBIT
          BlocProvider(create: (_) => FavoritesCubit()),

          /// CATEGORIES CUBIT
          BlocProvider(create: (_) => CategoriesCubit()),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp(
              title: 'Event App',
              debugShowCheckedModeBanner: false,

              //  CRITICAL: Add localization delegates
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              //  CRITICAL: Add supported locales
              supportedLocales: const [
                Locale('en', ''),
                Locale('fr', ''),
                Locale('ar', ''),
              ],

              //  CRITICAL: Set current locale from cubit
              locale: locale,

              theme: ThemeData(
                primaryColor: const Color.fromARGB(255, 66, 22, 79),
                scaffoldBackgroundColor: Colors.white,
                useMaterial3: true,
              ),

              //  Named routes for navigation
              routes: {
                '/login': (context) => const LoginScreen(),
                '/onboarding': (context) => const OnboardingScreen(),
                '/home': (context) => const HomeScreen(),
              },

              home:BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      //  Initialize user data BEFORE navigating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserCubit>().setUser(state.user);
        context.read<FavoritesCubit>().loadFavorites();
      });
      return const HomeScreen();
    }

                  if (state is AuthLoading) {
                    return const Scaffold(
                      backgroundColor: Colors.white,
                      body: Center(
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 66, 22, 79),
                        ),
                      ),
                    );
                  }

                  return const OnboardingScreen();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
