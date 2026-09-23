import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  Timer? _timer;
  int _remainingSeconds = 40;
  bool _isVerifying = false;
  bool _isResending = false;
  String _otpCode = "";

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    setState(() {
      _remainingSeconds = 40;
      _otpCode = "";
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (value == "backspace") {
        if (_otpCode.isNotEmpty) {
          _otpCode = _otpCode.substring(0, _otpCode.length - 1);
        }
      } else {
        if (_otpCode.length < 6 && _remainingSeconds > 0) {
          _otpCode += value;
          if (_otpCode.length == 6) {
            _verifyOtp();
          }
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await ApiService.verifyOtp(widget.email, _otpCode);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP Verified Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Navigate to your home/dashboard screen here
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Invalid OTP code. Try again."),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _otpCode = "";
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final bool success = await ApiService.sendOtp(widget.email);
      if (!mounted) return;

      if (success) {
        _startCountdownTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("New OTP sent! Check your email."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to resend OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error resending OTP: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2230),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text(
              "បញ្ជាក់កូដសុវត្ថិភាព",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "ការបញ្ជាក់ OTP ត្រូវបានបញ្ជូនទៅកាន់ ${widget.email} សូមពិនិត្យអ៊ីម៉ែលរបស់អ្នក",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 30),

            if (_remainingSeconds > 0) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _remainingSeconds / 40,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.amber,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          '$_remainingSeconds',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "ពេលវាល់ពេលវេលា",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ] else ...[
              TextButton(
                onPressed: _isResending ? null : _handleResendOtp,
                child: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber,
                        ),
                      )
                    : const Text(
                        "ផ្ញើសារជាថ្មី (Resend OTP)",
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _otpCode.length
                        ? Colors.amber
                        : Colors.grey.shade700,
                  ),
                );
              }),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _buildKeypadRow(["1", "2", "3"]),
                  const SizedBox(height: 10),
                  _buildKeypadRow(["4", "5", "6"]),
                  const SizedBox(height: 10),
                  _buildKeypadRow(["7", "8", "9"]),
                  const SizedBox(height: 10),
                  _buildKeypadRow(["", "0", "backspace"]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 80, height: 50);
        }
        if (key == "backspace") {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onKeyPressed("backspace"),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 50,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
              ),
            ),
          );
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onKeyPressed(key),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 50,
              alignment: Alignment.center,
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}