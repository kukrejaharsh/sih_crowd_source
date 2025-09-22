import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sih_crowd_source/src/data/providers/auth_state_provider.dart';
import 'package:sih_crowd_source/src/features/dashboard/screens/dashboard_screen.dart';
import 'package:sih_crowd_source/src/features/entry_point/screens/entry_screen.dart'; // Import your splash screen UI

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.authState) {
          case AuthState.authenticated_profile_loaded:
            // When the user profile is loaded, show the dashboard.
            return const DashboardScreen();

          case AuthState.unauthenticated:
            // When the user is logged out, show the entry/onboarding screen.
            return const EntryScreen();

          case AuthState.loading:
          case AuthState.authenticated_profile_loading:
          default:
            // While checking auth or loading the profile, show your splash screen UI.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}



