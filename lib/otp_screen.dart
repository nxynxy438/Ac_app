import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId; 
  
  const OtpScreen({
    super.key, 
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otpCode = '';
  bool _isLoading = false;

  void _onKeyPressed(String value) {
    if (_otpCode.length < 6 && !_isLoading) {
      setState(() {
        _otpCode += value;
      });

      if (_otpCode.length == 6) {
        _verifyOTPCodeUIOnly();
      }
    }
  }

  void _onDeletePressed() {
    if (_otpCode.isNotEmpty && !_isLoading) {
      setState(() {
        _otpCode = _otpCode.substring(0, _otpCode.length - 1);
      });
    }
  }

  // Simulated UI-only verification (No Firebase call, no SMS sent)
  Future<void> _verifyOTPCodeUIOnly() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a brief loading state for the UI (Fixed the missing closing parenthesis here)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("UI Design Test Successful! (No SMS sent)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF192A56),
      appBar: AppBar(
        backgroundColor: const Color(0xFF192A56),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ចុះឈ្មោះអេស៊ីលីដាមូប៊ីល',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Image.asset(
                'assets/image.png',
                height: 24,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.star,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ការផ្ទៀងផ្ទាត់សុវត្ថិភាព',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'លេខសម្ងាត់ OTP ត្រូវបានផ្ញើទៅ ${widget.phoneNumber} សូមប្រាកដថាស៊ីមកាតនេះត្រូវបានបញ្ចូលក្នុងទូរស័ព្ទនេះ។',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 85,
                        height: 85,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      Text(
                        '30',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ពេលវេលានៅសល់',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      bool hasDigit = index < _otpCode.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasDigit ? const Color(0xFFFFD700) : Colors.white30,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFE4E9F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'ពីការធ្វើសារដែលកំពុងចាំលេខកូដសារ',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                _buildKeypadRow([
                  {'num': '1', 'sub': ''},
                  {'num': '2', 'sub': 'ABC'},
                  {'num': '3', 'sub': 'DEF'},
                ]),
                const SizedBox(height: 8),
                _buildKeypadRow([
                  {'num': '4', 'sub': 'GHI'},
                  {'num': '5', 'sub': 'JKL'},
                  {'num': '6', 'sub': 'MNO'},
                ]),
                const SizedBox(height: 8),
                _buildKeypadRow([
                  {'num': '7', 'sub': 'PQRS'},
                  {'num': '8', 'sub': 'TUV'},
                  {'num': '9', 'sub': 'WXYZ'},
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 105),
                    _buildKeyButton('0', ''),
                    _buildDeleteButton(),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<Map<String, String>> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key['num']!, key['sub']!)).toList(),
    );
  }

  Widget _buildKeyButton(String text, String subText) {
    return SizedBox(
      width: 105,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : () => _onKeyPressed(text),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.1),
            ),
            if (subText.isNotEmpty)
              Text(
                subText,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black54, letterSpacing: 1.0),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 105,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: _isLoading ? null : _onDeletePressed,
        child: const Icon(Icons.backspace_outlined, size: 18, color: Colors.black87),
      ),
    );
  }
}