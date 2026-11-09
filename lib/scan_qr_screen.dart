import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import 'user_session.dart';

/// Full-screen camera scanner: the live camera fills the whole screen and the
/// header, scan frame, buttons are drawn on top of it.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  static const _bar = Color(0xFF1F2C45);
  static const _gold = Color(0xFFC9A548);
  static const _text = Color(0xFFF2F4F8);
  static const _frameColor = Color(0xFFFFC21A);

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  bool _handled = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _line.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ---------- Scanning ----------
  Future<void> _onDetect(BarcodeCapture capture) async {
    final raw = _firstValue(capture);
    if (raw != null) await _handleRaw(raw);
  }

  String? _firstValue(BarcodeCapture? capture) {
    if (capture == null) return null;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Future<void> _handleRaw(String raw) async {
    if (_handled) return;
    _handled = true;
    HapticFeedback.mediumImpact();
    await _controller.stop();
    if (!mounted) return;

    await _showResult(raw);

    if (!mounted) return;
    _handled = false;
    await _controller.start();
  }

  // Choose a QR image from the phone gallery / files
  Future<void> _pickFromGallery() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      final path = file?.path;
      if (path == null) return;

      final capture = await _controller.analyzeImage(path);
      final raw = _firstValue(capture);
      if (raw == null) {
        _snack('No QR code found in this image');
        return;
      }
      await _handleRaw(raw);
    } catch (e) {
      _snack('Could not read image: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Check the scanned account on the server ----------
  /// Returns {name} when the account exists, {} when the server answered
  /// "not found", or null when the server could not be reached / checked.
  Future<Map<String, String>?> _checkAccount(String email) async {
    try {
      final uri = Uri.parse('${UserSession.baseUrl}/api/v1/profile/by-email')
          .replace(queryParameters: {'email': email});
      final res = await http.get(uri).timeout(const Duration(seconds: 6));

      Map<dynamic, dynamic>? body;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) body = decoded;
      } catch (_) {}
      if (body == null) return null; // not our API (e.g. route missing)

      if (res.statusCode == 200 && body['success'] == true) {
        final d = body['data'];
        String name = '';
        if (d is Map) {
          final f = (d['firstName'] ?? d['first_name'] ?? '').toString();
          final l = (d['lastName'] ?? d['last_name'] ?? '').toString();
          name = '$f $l'.trim();
        }
        return {'name': name};
      }
      if (res.statusCode == 404 && body['success'] == false) return {};
      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------- Result sheet ----------
  static const _ok = Color(0xFF4CAF50);
  static const _bad = Color(0xFFE57373);

  Widget _header(IconData icon, Color color, String title) => Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );

  Future<void> _showResult(String raw) {
    final info = _parseQrPayload(raw);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: info == null ? _invalidBody(ctx, raw) : _validBody(ctx, info),
      ),
    );
  }

  Map<String, String>? _parseQrPayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['email'] is String) {
        final email = (decoded['email'] as String).trim();
        if (email.isEmpty) return null;
        final name = decoded['name'];
        return {
          'email': email,
          if (name is String) 'name': name,
        };
      }
    } catch (_) {
      // Try a URL-style QR payload below.
    }

    final uri = Uri.tryParse(raw);
    final email = uri?.queryParameters['email']?.trim();
    if (email == null || email.isEmpty) return null;
    final name = uri!.queryParameters['name'];
    return {'email': email, if (name != null) 'name': name};
  }

  // Not one of our QR codes -> invalid
  Widget _invalidBody(BuildContext ctx, String raw) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(Icons.cancel_rounded, _bad, 'QR is invalid'),
        const SizedBox(height: 8),
        const Text(
          'This is not a Khmer Bank QR code.',
          style: TextStyle(color: Color(0xFFA9B6CC)),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF16233D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: SelectableText(raw, style: const TextStyle(color: _text)),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: raw));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          icon: const Icon(Icons.copy_rounded, color: _gold, size: 18),
          label: const Text('Copy', style: TextStyle(color: _gold)),
        ),
      ],
    );
  }

  // Our QR code -> check the account, then show valid / invalid
  Widget _validBody(BuildContext ctx, Map<String, String> info) {
    final email = info['email']!;
    return FutureBuilder<Map<String, String>?>(
      future: _checkAccount(email),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: _gold)),
          );
        }

        final result = snap.data; // null = could not check
        if (result != null && result.isEmpty) {
          // Server says this account does not exist
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(Icons.cancel_rounded, _bad, 'QR is invalid'),
              const SizedBox(height: 8),
              Text(
                'No account found for $email.',
                style: const TextStyle(color: Color(0xFFA9B6CC)),
              ),
            ],
          );
        }

        final serverName = result?['name'] ?? '';
        final name = serverName.isNotEmpty ? serverName : (info['name'] ?? '');
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(Icons.check_circle_rounded, _ok, 'QR is valid'),
            const SizedBox(height: 16),
            Text(
              name.isNotEmpty ? name : 'Unknown name',
              style: const TextStyle(
                  color: _text, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: Color(0xFFA9B6CC))),
            if (result == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Could not reach the server to confirm this account.',
                style: TextStyle(color: Color(0xFFA9B6CC), fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: const Color(0xFF1A2845),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // TODO: open your transfer screen with this receiver, e.g.
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => TransferScreen(toEmail: email)));
                  _snack('Transfer to $email');
                },
                child: const Text('Transfer money',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frame = size.width * 0.7;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1) Live camera = the real background, full screen
            MobileScanner(controller: _controller, onDetect: _onDetect),

            // 2) Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black26,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'ទូទាត់តាម QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.info_outline,
                          color: Colors.white, size: 20),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2C45),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/Acleda.png',
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.eco, color: _gold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3) Scan frame with gold corners + moving line
            Align(
              alignment: const Alignment(0, -0.32),
              child: SizedBox(
                width: frame,
                height: frame,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(frame, frame),
                      painter: _CornerPainter(_frameColor),
                    ),
                    AnimatedBuilder(
                      animation: _line,
                      builder: (_, __) => Positioned(
                        left: 14,
                        right: 14,
                        top: 14 + (frame - 28) * _line.value,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: _frameColor,
                            boxShadow: const [
                              BoxShadow(color: Color(0x99FFC21A), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4) Pay-with row + bottom buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ទូទាត់បានជាមួយ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _PayWithRow(),
                      const SizedBox(height: 26),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RoundAction(
                            icon: _torchOn
                                ? Icons.flashlight_on_rounded
                                : Icons.flashlight_off_rounded,
                            label: 'ពន្លឺ',
                            onTap: () async {
                              await _controller.toggleTorch();
                              setState(() => _torchOn = !_torchOn);
                            },
                          ),
                          const SizedBox(width: 56),
                          _RoundAction(
                            icon: Icons.ios_share_rounded,
                            label: 'ជ្រើសរើស QR',
                            onTap: _pickFromGallery,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold rounded corner brackets (the scan frame).
class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const len = 62.0;
    const r = 26.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;

    // top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, len)
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(len, 0),
      p,
    );
    // top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, 0)
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, len),
      p,
    );
    // bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, h - len)
        ..lineTo(0, h - r)
        ..arcToPoint(Offset(r, h),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(len, h),
      p,
    );
    // bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - len, h)
        ..lineTo(w - r, h)
        ..arcToPoint(Offset(w, h - r),
            radius: const Radius.circular(r), clockwise: false)
        ..lineTo(w, h - len),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.color != color;
}

/// Row of accepted-payment badges. Replace the text with your own logo
/// images (Image.asset) when you have them.
class _PayWithRow extends StatelessWidget {
  const _PayWithRow();

  static const _items = [
    ('KHQR', Color(0xFFE1232E)),
    ('VISA', Color(0xFF1A1F71)),
    ('MC', Color(0xFFEB001B)),
    ('UPI', Color(0xFF00629B)),
    ('VietQR', Color(0xFF1E88E5)),
    ('LAPNet', Color(0xFF0B3C7D)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final it in _items)
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              it.$1,
              style: TextStyle(
                color: it.$2,
                fontSize: it.$1.length > 4 ? 8.5 : 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: Color(0x66808890),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
      ],
    );
  }
}