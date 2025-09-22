// lib/src/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:sih_crowd_source/src/features/dashboard/screens/dashboard_screen.dart';
import 'package:sih_crowd_source/src/features/entry_point/screens/entry_screen.dart';
import 'package:sih_crowd_source/src/features/issue_reporting/screens/report_issue_screen.dart';
import 'package:sih_crowd_source/src/features/login/screens/login_screen.dart';
import 'package:sih_crowd_source/src/features/register/screens/register_screen.dart';
import 'package:sih_crowd_source/src/features/report_list/screens/my_reports_screen.dart';

class AppRouter {
  // Define static constant route names to avoid typos
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String reportIssueRoute = '/reportIssue';
  static const String myReportsRoute = '/myReports';
  static const String entryRoute = '/entry';

  // Map route names to their corresponding screen widgets
  static final Map<String, WidgetBuilder> routes = {
    loginRoute: (context) => const LoginScreen(),
    registerRoute: (context) => const RegisterScreen(),
    dashboardRoute: (context) => const DashboardScreen(),
    reportIssueRoute: (context) => const SubmitReportScreen(),
    myReportsRoute: (context) => const MyReportsScreen(),
    entryRoute: (context) => const EntryScreen(),

  };
}