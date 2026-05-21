import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/home_screen.dart';

class MyMoveApp extends StatelessWidget {
  const MyMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Check if user is logged in
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show splash screen while checking auth
          if (authProvider.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Navigate based on auth status
          return authProvider.isAuthenticated 
              ? const HomeScreen() 
              : const OnboardingScreen();
        },
      ),
      
      // Define routes
      routes: AppRoutes.routes,
    );
  }
}