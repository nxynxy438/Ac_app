import 'package:flutter/material.dart';

import 'home_screen.dart'; // <-- NEW: home screen
import 'user_session.dart'; // <-- NEW: saves the PIN on the device

/// Required PIN length (any characters: letters, digits, symbols like @!#).
const int _pinLength = 8;

class _Colors {
  _Colors._();
  static const bg = Color(0xFF25344F);
  static const bar = Color(0xFF1F2C45);
  static const gold = Color(0xFFC9A548);
  static const text = Color(0xFFF2F4F8);
  static const field = Color(0xFFF7F7F9);
  static const error = Color(0xFFFF9B9B);
  static const success = Color(0xFF9BE3B0);
}

class RegisterPinScreen extends StatefulWidget {
  final String email; // passed from RegisterProfileScreen

  const RegisterPinScreen({super.key, this.email = ''});

  @override
  State<RegisterPinScreen> createState() => _RegisterPinScreenState();
}

class _RegisterPinScreenState extends State<RegisterPinScreen> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _confirmFocus = FocusNode();
  String _message = '';
  bool _ok = false;
  bool _saving = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (_pinCtrl.text.length != _pinLength) {
      setState(() {
        _ok = false;
        _message = 'PIN must be exactly $_pinLength characters.';
      });
      return;
    }
    if (_pinCtrl.text != _confirmCtrl.text) {
      setState(() {
        _ok = false;
        _message = 'PINs do not match.';
      });
      return;
    }
    _saving = true;
    // NEW: store the PIN securely on the device (salted hash, not plain text)
    await UserSession.instance.savePin(_pinCtrl.text);
    if (!mounted) return;
    // Optional: also send widget.email + the PIN to your backend here.
    setState(() {
      _ok = true;
      _message = 'PIN created.';
      _saving = false;
    });

    // NEW: go to the Home screen and clear the register screens from the back stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg, // navy page, independent of the app theme
      appBar: _TopBar(onBack: () => Navigator.maybePop(context)),
      body: Stack(
        children: [
          // Decorative waves
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 240,
            child: IgnorePointer(
              child: CustomPaint(painter: _WavePainter()),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 24),
              child: Column(
                children: [
                  const CustomPaint(
                    size: Size(52, 56),
                    painter: _ShieldPainter(),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'បង្កើតលេខសម្ងាត់គណនីរបស់អ្នក',
                    style: TextStyle(
                      color: _Colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _PinField(
                    controller: _pinCtrl,
                    label: 'Login PIN',
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() => _message = ''),
                    onSubmitted: (_) => _confirmFocus.requestFocus(),
                  ),
                  const SizedBox(height: 22),
                  _PinField(
                    controller: _confirmCtrl,
                    label: 'Confirm login PIN',
                    focusNode: _confirmFocus,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _message = ''),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 18,
                    child: Text(
                      _message,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ok ? _Colors.success : _Colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(onPressed: _submit),
    );
  }
}

/// Top bar: back arrow, centered title, logo on the right.
class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Colors.bar,
        boxShadow: [
          BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _Colors.text, size: 20),
              ),
              const Expanded(
                child: Text('បង្កើតលេខសម្ងាត់',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _Colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              // Replace with your own logo, e.g. Image.asset('assets/logo.png')
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 8),
                child: Image.asset(
                  'assets/Acleda.png', // must be listed in pubspec.yaml
                  width: 26,
                  height: 26,
                  errorBuilder: (_, __, ___) => const CustomPaint(
                    size: Size(26, 26),
                    painter: _LogoPainter(),
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

/// White rounded PIN input.
class _PinField extends StatelessWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
    this.focusNode,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: true,
        obscuringCharacter: '•',
        keyboardType: TextInputType.visiblePassword, // letters, digits and symbols
        textInputAction: textInputAction,
        maxLength: _pinLength,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        cursorColor: _Colors.bar,
        style: const TextStyle(
          fontSize: 16,
          letterSpacing: 5,
          color: Color(0xFF1D2638),
        ),
        decoration: InputDecoration(
          counterText: '',
          isDense: true,
          filled: true,
          fillColor: _Colors.field,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFAAB2C0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: _Colors.gold, width: 2),
          ),
        ),
      ),
    );
  }
}

/// Bottom bar with the gold OK button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _Colors.bar,
        boxShadow: [
          BoxShadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: _Colors.gold,
              shape: const RoundedRectangleBorder(),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: _Colors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold shield with a check mark.
class _ShieldPainter extends CustomPainter {
  const _ShieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 52;
    final sy = size.height / 56;
    final paint = Paint()
      ..color = _Colors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final shield = Path()
      ..moveTo(26 * sx, 3 * sy)
      ..lineTo(5 * sx, 11 * sy)
      ..lineTo(5 * sx, 27 * sy)
      ..cubicTo(5 * sx, 40 * sy, 14 * sx, 49 * sy, 26 * sx, 53 * sy)
      ..cubicTo(38 * sx, 49 * sy, 47 * sx, 40 * sy, 47 * sx, 27 * sy)
      ..lineTo(47 * sx, 11 * sy)
      ..close();
    canvas.drawPath(shield, paint);

    final check = Path()
      ..moveTo(17 * sx, 28 * sy)
      ..lineTo(24 * sx, 35 * sy)
      ..lineTo(36 * sx, 21 * sy);
    canvas.drawPath(check, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Simple placeholder logo (gold bird shape).
class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 26;
    final gold = Paint()..color = _Colors.gold;
    final white = Paint()..color = _Colors.text;

    final body = Path()
      ..moveTo(2 * s, 4 * s)
      ..cubicTo(8 * s, 5 * s, 12 * s, 8 * s, 14 * s, 13 * s)
      ..lineTo(17 * s, 8 * s)
      ..lineTo(24 * s, 6 * s)
      ..lineTo(18 * s, 13 * s)
      ..lineTo(16 * s, 21 * s)
      ..lineTo(13 * s, 16 * s)
      ..lineTo(9 * s, 17 * s)
      ..close();
    canvas.drawPath(body, gold);

    final wing = Path()
      ..moveTo(13 * s, 13 * s)
      ..cubicTo(12 * s, 16 * s, 10 * s, 18 * s, 7 * s, 19 * s)
      ..cubicTo(10 * s, 19 * s, 13 * s, 18 * s, 15 * s, 15 * s)
      ..close();
    canvas.drawPath(wing, white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Soft translucent waves at the bottom of the screen.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    Paint gradient(Color end) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [const Color(0x00FFFFFF), end],
      ).createShader(rect);

    final back = Path()
      ..moveTo(0, h * 0.83)
      ..cubicTo(w * 0.24, h * 0.62, w * 0.53, h * 0.70, w * 0.74, h * 0.50)
      ..cubicTo(w * 0.90, h * 0.35, w * 0.95, h * 0.17, w, h * 0.08)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, gradient(const Color(0x29FFFFFF)));

    final front = Path()
      ..moveTo(0, h * 0.96)
      ..cubicTo(w * 0.26, h * 0.80, w * 0.50, h * 0.83, w * 0.71, h * 0.67)
      ..cubicTo(w * 0.92, h * 0.50, w * 0.95, h * 0.38, w, h * 0.30)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, gradient(const Color(0x4DFFFFFF)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}