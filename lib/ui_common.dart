import 'package:flutter/material.dart';

/// Colors shared by the Accounts / Transfer screens.
class AppColors {
  AppColors._();
  static const navy = Color(0xFF1B3052);
  static const navyDark = Color(0xFF13253E);
  static const gold = Color(0xFFC9A548);
  static const sheet = Color(0xFFF2F2F4);
  static const text = Color(0xFF1E2F4D);
  static const muted = Color(0xFF8A94A6);
  static const blue = Color(0xFF2F4FA3);
  static const border = Color(0xFFD5D9E0);
  static const red = Color(0xFFE53935);
  static const green = Color(0xFF2E9E5B);
}

/// Page transition: slides in from the right.
Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

void showSoon(BuildContext context, String name) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$name – coming soon')));
}

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/Acleda.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.eco, color: AppColors.gold, size: size * 0.8),
    );
  }
}

/// Navy top bar: round back button, title, optional (i) icon, logo.
class ScreenHeader extends StatelessWidget {
  final String title;
  final bool showInfo;
  const ScreenHeader({super.key, required this.title, this.showInfo = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.maybePop(context),
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0x33FFFFFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showInfo) ...[
            const SizedBox(width: 8),
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 20),
          ],
          const Spacer(),
          const AppLogo(),
        ],
      ),
    );
  }
}