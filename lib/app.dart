import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

class MyMoveApp extends StatefulWidget {
  const MyMoveApp({super.key});

  @override
  State<MyMoveApp> createState() => _MyMoveAppState();
}

class _MyMoveAppState extends State<MyMoveApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'myMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      
      // Navigate dynamically based on splash screen and auth check
      home: _showSplash
          ? SplashScreen(
              onTimeout: () {
                if (mounted) {
                  setState(() {
                    _showSplash = false;
                  });
                }
              },
            )
          : Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                // Show standard fallback loader if auth state isn't initialized yet
                if (!authProvider.isInitialChecked) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                // Once checked, render HomeScreen or OnboardingScreen based on current user state
                debugPrint("MyMoveApp Auth State Build: isAuthenticated=${authProvider.isAuthenticated}, uid=${authProvider.user?.uid}");
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