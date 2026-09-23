import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEntered = false;
  bool _isLoading = false; 

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        _isEntered = _emailController.text.isNotEmpty;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();

    try {
      bool success = await ApiService.sendOtp(email);

      if (!mounted) return;

      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              email: email, 
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send OTP. Please check your email or database."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Network Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                        'បញ្ចូលអ៊ីមែលរបស់អ្នកដើម្បីទទួលកូដ OTP',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2238).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.white70),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                focusNode: _focusNode,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                keyboardType: TextInputType.emailAddress, 
                                decoration: const InputDecoration(
                                  hintText: 'បញ្ចូលអ៊ីមែល (Email)',
                                  hintStyle: TextStyle(color: Colors.white38),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_isEntered)
                              GestureDetector(
                                onTap: () => _emailController.clear(),
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
                    onPressed: (_isEntered && !_isLoading) ? _sendEmailOtp : null,
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