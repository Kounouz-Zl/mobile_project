 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/user/user_cubit.dart';
import 'bloc/events/events_cubit.dart';
import 'bloc/favorites/favorites_cubit.dart';
import 'bloc/categories/categories_cubit.dart';
import 'repositories/auth_repository.dart';
import 'repositories/events_repository.dart';
import 'repositories/user_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize sqflite FFI ONLY for Desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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
            create: (context) => UserCubit(
              userRepository: context.read<UserRepository>(),
            ),
          ),

          /// EVENTS CUBIT
          BlocProvider(
            create: (context) => EventsCubit(
              eventsRepository: context.read<EventsRepository>(),
            )..fetchEvents(),
          ),

          BlocProvider(create: (_) => FavoritesCubit()),
          BlocProvider(create: (_) => CategoriesCubit()),
        ],
        child: MaterialApp(
          title: 'Event App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color.fromARGB(255, 66, 22, 79),
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserCubit>().setUser(state.user);
        context.read<FavoritesCubit>().setUserId(state.user.id); // Add this
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
        ),
      ),
    );
  }
}
