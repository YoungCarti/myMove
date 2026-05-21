import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          // To change the background image, download your desired image and place it in the 'assets/images/' directory.
          // Then, update your pubspec.yaml to include that asset, and replace the Image.network below with:
          // Image.asset('assets/images/your_image_name.png', fit: BoxFit.cover),
          Image.network(
            'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1E1E2C), // Fallback dark color
              );
            },
          ),
          
          // Dark overlay to make text readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  
                  // The word in the middle - Sleek Apple/Instagram-like neo-grotesque typography
                  Text(
                    'myMove',
                    style: GoogleFonts.merriweather(
                      fontSize: 64,
                      fontWeight: FontWeight.w800, // Elegant, bold serif style
                      color: Colors.white,
                      letterSpacing: -2.0,
                      height: 1.1,
                    ),
                  ),
                  
                  const Spacer(flex: 3),
                  
                  // "Get Started Here" flowing button - now at the bottom
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3A8DFF), Color(0xFF0044C9)], // Flowing premium gradient
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          // Navigate to Login/Register screen
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Center(
                          child: Text(
                            'Get Started Here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2, // Clean modern letter spacing
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
