import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => EventsRepository()),
        RepositoryProvider(create: (context) => UserRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(const CheckAuthStatus()),
          ),
          BlocProvider(
            create: (context) => UserCubit(
              userRepository: context.read<UserRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => EventsCubit(
              eventsRepository: context.read<EventsRepository>(),
            )..fetchEvents(),
          ),
          BlocProvider(create: (context) => FavoritesCubit()),
          BlocProvider(create: (context) => CategoriesCubit()),
        ],
        child: MaterialApp(
          title: 'Event App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: const Color.fromARGB(255, 66, 22, 79),
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: Colors.white,
            useMaterial3: true,
          ),
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                // Set user in UserCubit
                context.read<UserCubit>().setUser(state.user);
                return const HomeScreen();
              }
              return const OnboardingScreen();
            },
          ),
        ),
      ),
    );
  }
}
