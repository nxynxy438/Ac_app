import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'account_store.dart';
import 'transaction_history.dart';
import 'transfer_menu_screen.dart';
import 'ui_common.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountStore _store = AccountStore.instance;
  int _tab = 0;

  static const _tabs = ['សមតុល្យ', 'គណនីជួញដូរ', 'ប័ណ្ណ', 'ភ្ជាប់'];

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  double get _usdShare {
    final usd = _store.totalUsd;
    final khrInUsd = _store.totalKhr / AccountStore.khrPerUsd;
    final total = usd + khrInUsd;
    if (total <= 0) return 0;
    return usd / total;
  }

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
                // Redesigned Top Header matching image two
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
                        'គណនី',
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
                const SizedBox(height: 14),
                _buildTabs(),
                const SizedBox(height: 16),
                _buildSummary(),
                const SizedBox(height: 20),
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
                child: _tab == 0 ? _buildAccountList() : _buildPlaceholder(),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ---------------- Tabs ----------------
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        color: _tab == i ? AppColors.navy : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- Donut + totals ----------------
  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: _DonutPainter(usdShare: _usdShare),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: Colors.white, size: 28),
                    SizedBox(height: 2),
                    Text('សរុប',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _totalPill(
                  AccountStore.format(_store.totalKhr, 'KHR'),
                  '៛',
                ),
                const SizedBox(height: 12),
                _totalPill(
                  AccountStore.format(_store.totalUsd, 'USD'),
                  r'$',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalPill(String amount, String symbol) {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                amount,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              symbol,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Account cards ----------------
  Widget _buildAccountList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      itemCount: _store.accounts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _accountCard(_store.accounts[i]),
    );
  }

  Widget _accountCard(Account a) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        slideRoute(TransactionHistoryScreen(accountId: a.id)),
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '•••',
                  style: TextStyle(
                    color: Color(0xFF5BA3E0),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                const Text(
                  'សមតុល្យប្រើបាន',
                  style: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  a.kind == AccountKind.wallet
                      ? Icons.account_balance_wallet_outlined
                      : Icons.account_balance_outlined,
                  color: const Color(0xFFC3C8D2),
                  size: 38,
                ),
                const Spacer(),
                Text(
                  '${a.balanceText} ${a.symbol}',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              a.number,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              a.name,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Text(
        '${_tabs[_tab]} – coming soon',
        style: const TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    );
  }

  // ---------------- Bottom bar ----------------
  Widget _buildBottomBar() {
    return Container(
      color: AppColors.navy,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          child: Row(
            children: [
              _BottomItem(
                icon: Icons.account_balance_outlined,
                label: 'គណនីថ្មី',
                onTap: () => showSoon(context, 'គណនីថ្មី'),
              ),
              _BottomItem(
                icon: Icons.swap_horizontal_circle_outlined,
                label: 'សេវារហ័ស',
                onTap: () => Navigator.push(
                  context,
                  slideRoute(const TransferMenuScreen()),
                ),
              ),
              _BottomItem(
                icon: Icons.pie_chart_outline_rounded,
                label: 'របាយការណ៍សង្ខេប',
                beta: true,
                onTap: () => showSoon(context, 'របាយការណ៍សង្ខេប'),
              ),
              _BottomItem(
                icon: Icons.history_rounded,
                label: 'ប្រវត្តិប្រតិបត្តិការ',
                onTap: () => Navigator.push(
                  context,
                  slideRoute(const TransactionHistoryScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool beta;
  final VoidCallback onTap;
  const _BottomItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.beta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 32),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (beta)
                Positioned(
                  top: -4,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2C94C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'បេតា',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
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

class _DonutPainter extends CustomPainter {
  final double usdShare;
  _DonutPainter({required this.usdShare});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 30.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    const start = -math.pi / 2;
    final khrSweep = 2 * math.pi * (1 - usdShare);
    final usdSweep = 2 * math.pi * usdShare;

    if (khrSweep > 0.001) {
      canvas.drawArc(
          rect, start, khrSweep, false, paint..color = const Color(0xFF6D9BD0));
    }
    if (usdSweep > 0.001) {
      canvas.drawArc(rect, start + khrSweep, usdSweep, false,
          paint..color = const Color(0xFFE8873A));
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.usdShare != usdShare;
}
