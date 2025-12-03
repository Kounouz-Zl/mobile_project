import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:p/bloc/events/events_cubit.dart';
import 'package:p/bloc/favorites/favorites_cubit.dart';
import 'package:p/database_helper.dart';
import 'package:p/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper();
    return MultiBlocProvider(
      providers: [
        BlocProvider<EventsCubit>(
          create: (context) => EventsCubit()..fetchEvents(),
        ),
        BlocProvider<FavoritesCubit>(
          create: (context) => FavoritesCubit(dbHelper)..fetchFavorites(),
        ),
      ],
      child: MaterialApp(
        title: 'Event App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
