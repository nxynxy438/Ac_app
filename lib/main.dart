import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import the login screen

void main() {
  runApp(const KhmerBankApp());
}

class KhmerBankApp extends StatelessWidget {
  const KhmerBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Khmer Bank',
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E2B4D),
              Color(0xFF3B4873),
              Color(0xFF233059),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // App Logo Container with Custom Image Asset
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF12233B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/image.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // WELCOME Text
              const Text(
                'WELCOME',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'AC SUPER APP "KHMER BANK"',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              
              const Spacer(flex: 2),

              // Bottom Language Selector Sheet Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2238).withValues(alpha: 0.75),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please select language',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Language Options Linked to Login Screen
                    _buildLanguageOption(
                      context: context, 
                      flagText: '🇰🇭', 
                      languageName: 'ភាសាខ្មែរ', 
                    ),
                    const SizedBox(height: 10),
                    _buildLanguageOption(
                      context: context, 
                      flagText: '🇬🇧', 
                      languageName: 'English', 
                    ),
                    const SizedBox(height: 10),
                    _buildLanguageOption(
                      context: context, 
                      flagText: '🇱🇦', 
                      languageName: 'ລາວ', 
                    ),
                    const SizedBox(height: 10),
                    _buildLanguageOption(
                      context: context, 
                      flagText: '🇨🇳', 
                      languageName: '中文', 
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String flagText, 
    required String languageName, 
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to the login/phone screen when clicked
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              alignment: Alignment.center,
              child: Text(flagText, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 16),
            Text(
              languageName,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}