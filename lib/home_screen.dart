import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'my_qr_screen.dart';
import 'scan_qr_screen.dart';
import 'user_session.dart';

class _C {
  _C._();
  static const bg = Color(0xFF1A2845);
  static const tile = Color(0xFF1C2E4E);
  static const tileBorder = Color(0xFF2F6A9E);
  static const gold = Color(0xFFC9A548);
  static const blue = Color(0xFF5BB5F0);
  static const text = Color(0xFFF2F4F8);
  static const muted = Color(0xFFA9B6CC);
  static const red = Color(0xFFE53935);
  static const nav = Color(0xFF2B3B5A);
}

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = ''});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = true;

  // Real data the user entered during registration (saved by UserSession)
  String get _displayName {
    final s = UserSession.instance;
    if (s.firstName.isNotEmpty) return s.firstName;
    return widget.userName.isNotEmpty ? widget.userName : 'Guest';
  }

  ImageProvider? get _avatarImage {
    final s = UserSession.instance;
    if (s.photoPath.isNotEmpty && File(s.photoPath).existsSync()) {
      return FileImage(File(s.photoPath));
    }
    if (s.photoUrl.isNotEmpty) return NetworkImage(s.photoUrl);
    return null;
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    UserSession.instance.addListener(_onSessionChanged);
    // Load the real profile (name, photo...) from the server; rebuilds when done
    UserSession.instance.syncFromServer();
  }

  @override
  void dispose() {
    UserSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  int _navIndex = 0;

  // Opens the real screen for a tile; others still show "coming soon"
  void _openTile(String label) {
    if (label == 'Scan QR') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanQrScreen()),
      );
    } else {
      _soon(label);
    }
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name – coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  _greeting(),
                  const SizedBox(height: 14),
                  _balanceCard(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _WideButton(
                          icon: Icons.receipt_long_outlined,
                          label: 'បង់ប្រាក់',
                          onTap: () => _soon('បង់ប្រាក់'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WideButton(
                          icon: Icons.phone_android_outlined,
                          label: 'បញ្ចូលទូរស័ព្ទ',
                          onTap: () => _soon('បញ្ចូលទូរស័ព្ទ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _tileRow([
                    _TileData(Icons.credit_card_outlined, 'ប័ណ្ណ'),
                    _TileData(Icons.qr_code_scanner, 'ទូទាត់តាម​ ​QR'),
                    _TileData(Icons.swap_horiz, 'ផ្ទេរប្រាក់'),
                  ]),
                  const SizedBox(height: 12),
                  _tileRow([
                    _TileData(Icons.bar_chart_rounded, 'ប្រាក់បញ្ញើ'),
                    _TileData(Icons.payments_outlined, 'ដកប្រាក់រហ័ស'),
                    _TileData(Icons.volunteer_activism_outlined, 'ប្រាក់កម្ចី'),
                  ]),
                  const SizedBox(height: 14),
                  _shortcuts(),
                  const SizedBox(height: 20),
                  const Text(
                    'បានណែនាំ',
                    style: TextStyle(
                      color: _C.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _banner(),
                ],
              ),
            ),
          ),

          // Voice assistant button
          Positioned(
            right: 24,
            bottom: 92,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF2F7DE1),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x662F7DE1),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 24),
            ),
          ),

          // Floating bottom navigation + chatbot button
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _bottomNav()),
                  const SizedBox(width: 10),
                  _chatBotButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Header ----------------
  Widget _header() {
    return Row(
      children: [
        Image.asset(
          'assets/Acleda.png', // add to pubspec.yaml assets
          height: 34,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.eco, color: _C.gold, size: 30),
        ),
        const SizedBox(width: 6),
        const Text(
          'អេស៊ីលីដា',
          style: TextStyle(
            color: _C.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () => _soon('Notifications'),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _C.text,
                size: 28,
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: _C.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyQrScreen()),
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- Greeting ----------------
  Widget _greeting() {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFB0B8C8),
          backgroundImage: _avatarImage,
          child: _avatarImage == null
              ? const Icon(Icons.person, color: Colors.white, size: 28)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'សួរស្ដី, $_displayName',
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _soon('Profile'),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ព័ត៍មានផ្ទាល់ខ្លួន',
                      style: TextStyle(color: _C.muted, fontSize: 13),
                    ),
                    Icon(Icons.chevron_right, color: _C.muted, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Balance card ----------------
  Widget _balanceCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _boxDecoration(radius: 20),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: CustomPaint(
              painter: _RingPainter(),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _C.text,
                      size: 26,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'គណនី',
                      style: TextStyle(color: _C.text, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'សមតុល្យសរុប',
                      style: TextStyle(color: _C.muted, fontSize: 13),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => _hideBalance = !_hideBalance),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B6EA5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _hideBalance
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _amount('1,250,000', '៛', _C.gold),
                const SizedBox(height: 10),
                _amount('1,250.00', r'$', _C.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amount(String value, String symbol, Color symbolColor) {
    Widget number = Text(
      value,
      style: const TextStyle(
        color: _C.text,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
    if (_hideBalance) {
      number = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: number,
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        number,
        const SizedBox(width: 6),
        Text(
          symbol,
          style: TextStyle(
            color: symbolColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ---------------- Tiles ----------------
  Widget _tileRow(List<_TileData> items) {
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _GridTile(
              data: items[i],
              onTap: () => _openTile(items[i].label),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- Shortcuts ----------------
  Widget _shortcuts() {
    const items = [
      _TileData(Icons.stars_rounded, 'ពិន្ទុរបស់ខ្ញុំ'),
      _TileData(Icons.storefront_outlined, 'ទាន់ចិត្តផេ'),
      _TileData(Icons.account_balance_outlined, 'សេវាកម្មសាធារណៈ'),
      _TileData(Icons.candlestick_chart_outlined, 'ជួញដូរភាគហ៊ុន'),
      _TileData(Icons.directions_car_outlined, 'ផ្សាកម្ពុជា'),
    ];
    return Container(
      height: 112,
      decoration: BoxDecoration(
        color: const Color(0xFF16233D),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) => InkWell(
          onTap: () => _openTile(items[i].label),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 78,
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF263A5E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3A5580)),
                  ),
                  child: Icon(items[i].icon, color: _C.gold, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  items[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _C.text,
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Banner ----------------
  Widget _banner() {
    return Container(
      height: 150,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFF2C94C), Color(0xFF7BAE5B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.topLeft,
      child: const SizedBox(
        width: 200,
        child: Text(
          'គណនីបញ្ញើតាមតម្រូវការ',
          style: TextStyle(
            color: Color(0xFF1A2845),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ---------------- Bottom navigation ----------------
  Widget _bottomNav() {
    const items = [
      _NavData(Icons.home_rounded, 'ទំព័រដើម'),
      _NavData(Icons.favorite_border_rounded, 'កំណត់ត្រា'),
      _NavData(Icons.chat_bubble_outline_rounded, 'សន្ទនា', beta: true),
      _NavData(Icons.menu_rounded, 'ម៉ឺនុយ'),
    ];
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _C.nav,
        borderRadius: BorderRadius.circular(31),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () {
                  setState(() => _navIndex = i);
                  if (i != 0) _soon(items[i].label);
                },
                child: _NavItem(data: items[i], selected: _navIndex == i),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chatBotButton() {
    return InkWell(
      onTap: () => _soon('Assistant'),
      customBorder: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF263A5E),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3A5580)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.smart_toy_outlined, color: _C.text, size: 28),
      ),
    );
  }
}

// ---------------- Helpers ----------------
BoxDecoration _boxDecoration({double radius = 16}) => BoxDecoration(
  color: _C.tile,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: _C.tileBorder, width: 1),
);

class _TileData {
  final IconData icon;
  final String label;
  const _TileData(this.icon, this.label);
}

class _GridTile extends StatelessWidget {
  final _TileData data;
  final VoidCallback onTap;
  const _GridTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        decoration: _boxDecoration(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: _C.text, size: 36),
            const SizedBox(height: 10),
            Text(
              data.label,
              style: const TextStyle(color: _C.text, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _WideButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _boxDecoration(),
        child: Row(
          children: [
            Icon(icon, color: _C.text, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _C.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final String label;
  final bool beta;
  const _NavData(this.icon, this.label, {this.beta = false});
}

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool selected;
  const _NavItem({required this.data, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? _C.gold : _C.text;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0x33C9A548) : Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
          if (data.beta)
            const Positioned(
              top: 0,
              right: 6,
              child: Text(
                'BETA',
                style: TextStyle(color: _C.text, fontSize: 7),
              ),
            ),
        ],
      ),
    );
  }
}

/// Blue + gold ring around the "Accounts" icon.
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      math.pi * 0.78,
      math.pi * 0.95,
      false,
      paint..color = _C.blue,
    );
    canvas.drawArc(
      rect,
      math.pi * 1.78,
      math.pi * 0.95,
      false,
      paint..color = _C.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
