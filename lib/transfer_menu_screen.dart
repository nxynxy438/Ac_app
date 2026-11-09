import 'package:flutter/material.dart';

import 'own_transfer_screen.dart';
import 'ui_common.dart';

class TransferMenuScreen extends StatelessWidget {
  const TransferMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 6),
                // Redesigned Top Header matching the Accounts screen layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0x33FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'ផ្ទេរប្រាក់',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const Spacer(),
                      const AppLogo(size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const _Illustration(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.sheet,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    _MenuCard(
                      iconBg: const Color(0xFF4A4FB0),
                      icon: Icons.swap_horiz_rounded,
                      title: 'គណនីផ្ទាល់ខ្លួន',
                      subtitle: 'ផ្ទេរប្រាក់ទៅគណនីផ្ទាល់ខ្លួន',
                      onTap: () => Navigator.push(
                        context,
                        slideRoute(const OwnTransferScreen()),
                      ),
                    ),
                    _MenuCard(
                      iconBg: AppColors.navy,
                      iconWidget: const AppLogo(size: 28),
                      title: 'គណនីអេស៊ីលីដា | លេខទូរសព្ទ',
                      subtitle: 'ផ្ទេរប្រាក់ទៅគណនីអេស៊ីលីដា | លេខទូរសព្ទ',
                      onTap: () =>
                          showSoon(context, 'គណនីអេស៊ីលីដា | លេខទូរសព្ទ'),
                    ),
                    _MenuCard(
                      iconBg: const Color(0xFF7B3FBF),
                      icon: Icons.account_balance_outlined,
                      title: 'ផ្ទេរប្រាក់ក្នុងប្រទេស',
                      subtitle: 'ផ្ទេរប្រាក់ទៅធនាគារ | MFIs | វ៉ាលឡេត',
                      showArrow: true,
                      onTap: () => showSoon(context, 'ផ្ទេរប្រាក់ក្នុងប្រទេស'),
                    ),
                    _MenuCard(
                      iconBg: const Color(0xFF0F6B6B),
                      icon: Icons.public_rounded,
                      title: 'ផ្ទេរប្រាក់ទៅក្រៅប្រទេស',
                      subtitle: 'ផ្ទេរប្រាក់ទៅធនាគារ | ភ្នាក់ងារពាសពេញពិភពលោក',
                      showArrow: true,
                      onTap: () =>
                          showSoon(context, 'ផ្ទេរប្រាក់ទៅក្រៅប្រទេស'),
                    ),
                    _MenuCard(
                      iconBg: const Color(0xFFC84BEB),
                      icon: Icons.credit_card_rounded,
                      title: 'ផ្ទេរប្រាក់ទៅប័ណ្ណ',
                      subtitle: 'ផ្ទេរប្រាក់ទៅប័ណ្ណរបស់ធនាគារផ្សេង',
                      showArrow: true,
                      badges: true,
                      onTap: () => showSoon(context, 'ផ្ទេរប្រាក់ទៅប័ណ្ណ'),
                    ),
                    _MenuCard(
                      iconBg: const Color(0xFFC9A22F),
                      icon: Icons.trending_up_rounded,
                      title: 'គណនីជួញដូរ',
                      subtitle:
                          'ផ្ទេរប្រាក់រវាងគណនីអេស៊ីលីដា និងគណនីជួញដូរ',
                      showArrow: true,
                      onTap: () => showSoon(context, 'គណនីជួញដូរ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.28,
            child: Container(
              width: 80,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF55B0F0), Color(0xFF1E6FC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const AppLogo(size: 20),
                ),
              ),
            ),
          ),
          const Align(
            alignment: Alignment(-0.35, -0.55),
            child: Icon(Icons.arrow_downward_rounded,
                color: Color(0xFFF2C94C), size: 56),
          ),
          const Align(
            alignment: Alignment(0.38, 0.4),
            child: Icon(Icons.arrow_upward_rounded,
                color: Color(0xFFF2C94C), size: 56),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Color iconBg;
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String subtitle;
  final bool showArrow;
  final bool badges;
  final VoidCallback onTap;

  const _MenuCard({
    required this.iconBg,
    this.icon,
    this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showArrow = false,
    this.badges = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: iconWidget ??
                      Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 12),
                Container(width: 1, color: const Color(0xFFE3E6EB)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (badges) ...[
                            const SizedBox(width: 8),
                            const _CardBadges(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showArrow)
                  const Icon(Icons.play_arrow_rounded,
                      color: AppColors.gold, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBadges extends StatelessWidget {
  const _CardBadges();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3CC4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 26,
          height: 18,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB001B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF79E1B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
