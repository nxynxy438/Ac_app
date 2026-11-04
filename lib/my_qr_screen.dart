import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'user_session.dart';

/// Builds / reads the text stored inside the QR code.
/// Short format (keeps the QR simple and easy to scan):
///   khmerbank://pay?e=<email>&n=<full name>
class QrPayload {
  QrPayload._();

  static String build({required String email, required String name}) {
    return Uri(
      scheme: 'khmerbank',
      host: 'pay',
      queryParameters: {
        'e': email,
        if (name.isNotEmpty) 'n': name,
      },
    ).toString();
  }

  /// Returns {email, name} when [raw] is one of our QR codes, otherwise null.
  static Map<String, String>? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'khmerbank' || uri.host != 'pay') {
      return null;
    }
    final q = uri.queryParameters;
    final email = q['e'] ?? q['email'] ?? '';
    if (email.isEmpty) return null;
    return {'email': email, 'name': q['n'] ?? q['name'] ?? ''};
  }
}

/// High-contrast QR: pure black on white, big quiet zone, low density.
class _QrView extends StatelessWidget {
  final String data;
  final double size;
  const _QrView({required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      padding: const EdgeInsets.all(12), // white "quiet zone" scanners need
      backgroundColor: Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }
}

class MyQrScreen extends StatelessWidget {
  const MyQrScreen({super.key});

  static const _bg = Color(0xFF1A2845);
  static const _bar = Color(0xFF1F2C45);
  static const _gold = Color(0xFFC9A548);
  static const _text = Color(0xFFF2F4F8);

  // Full-screen white page with the biggest possible QR (easiest to scan)
  void _enlarge(BuildContext context, String data, String name) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.white,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _QrView(
                    data: data,
                    size: MediaQuery.of(ctx).size.width - 24,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap anywhere to close',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = UserSession.instance;
    final name = s.fullName.isNotEmpty ? s.fullName : 'My account';
    final hasData = s.email.isNotEmpty;
    final data = hasData ? QrPayload.build(email: s.email, name: s.fullName) : '';
    final qrSize = (MediaQuery.of(context).size.width - 48 - 48).clamp(200.0, 320.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bar,
        foregroundColor: _text,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'MY QR',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.9),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A2845),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.email,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7690)),
                      ),
                      const SizedBox(height: 14),
                      if (hasData)
                        GestureDetector(
                          onTap: () => _enlarge(context, data, name),
                          child: _QrView(data: data, size: qrSize),
                        )
                      else
                        const SizedBox(
                          height: 240,
                          child: Center(
                            child: Text(
                              'Register first to get your QR code.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF6B7690)),
                            ),
                          ),
                        ),
                      if (hasData) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the code to enlarge',
                          style: TextStyle(fontSize: 12, color: Color(0xFF6B7690)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Show this code to receive money.\nThe sender scans it with Scan QR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA9B6CC), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                if (hasData)
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: data));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('QR text copied')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: _gold, size: 18),
                    label: const Text('Copy QR text', style: TextStyle(color: _gold)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}