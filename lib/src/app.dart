import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/authWrapper.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/data/providers/report_state_provider.dart';
import 'package:sih_crowd_source/src/routing/app_router.dart';
import 'package:sih_crowd_source/src/constants/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // I have used the consistent name AuthProvider here.
        // If you've renamed it to AuthStateProvider, make sure it's consistent everywhere.
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Civic Issue Reporter',
        theme: AppTheme.lightTheme,
        // THIS IS THE FIX: The AuthWrapper is now the home widget.
        home: const AuthWrapper(),
        routes: AppRouter.routes,
      ),
    );
  }
}

