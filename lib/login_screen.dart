import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp_screen.dart'; // Links to your OTP screen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEntered = false;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isEntered = _phoneController.text.isNotEmpty;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
    });

    String rawNumber = _phoneController.text.trim();
    if (rawNumber.startsWith('0')) {
      rawNumber = rawNumber.substring(1);
    }
    String fullPhoneNumber = '+855$rawNumber';

    FirebaseAuth auth = FirebaseAuth.instance;
    bool codeSentTriggered = false;

    try {
      // We wrap the verification in a 3-second timeout race
      await Future.any([
        auth.verifyPhoneNumber(
          phoneNumber: fullPhoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            if (codeSentTriggered) return;
            codeSentTriggered = true;
            await auth.signInWithCredential(credential);
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          verificationFailed: (FirebaseAuthException e) {
            if (codeSentTriggered) return;
            codeSentTriggered = true;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Verification Failed: ${e.message}")),
            );
          },
          codeSent: (String verificationId, int? resendToken) {
            if (codeSentTriggered) return;
            codeSentTriggered = true;
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpScreen(
                  verificationId: verificationId,
                  phoneNumber: fullPhoneNumber,
                ),
              ),
            );
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        ),
        // Forces a timeout error if Firebase takes more than 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (!codeSentTriggered) {
            throw Exception("Request timed out. Please check your network or test configuration.");
          }
        })
      ]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Always unlocks the button immediately on timeout/error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Timeout / Error: ${e.toString()}")),
      );
    }
  }

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'សូមស្វាគមន៍',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'សេចក្តីសង្ខេប "ធនាគារ អេស៊ីលីដា"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🇰🇭', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            const Text(
                              '+855',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.white70),
                            const SizedBox(width: 8),
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _phoneController,
                                focusNode: _focusNode,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                keyboardType: TextInputType.phone, 
                                decoration: const InputDecoration(
                                  hintText: 'បញ្ចូលលេខទូរស័ព្ទ',
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_isEntered)
                              GestureDetector(
                                onTap: () => _phoneController.clear(),
                                child: const Icon(Icons.clear, color: Colors.white54, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isEntered && !_isLoading) ? _verifyPhoneNumber : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B6CB0),
                      disabledBackgroundColor: Colors.white24,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'យល់ព្រម',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}