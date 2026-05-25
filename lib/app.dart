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
      
      // Navigate dynamically based on initial auth check
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show splash loading screen ONLY during the very first app startup auth check
          if (!authProvider.isInitialChecked) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // Once checked, render HomeScreen or OnboardingScreen based on current user state
          debugPrint("MyMoveApp Auth State Build: isAuthenticated=${authProvider.isAuthenticated}, user=${authProvider.user?.email}");
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