import 'package:flutter/material.dart';

import 'account_store.dart';
import 'transaction_history.dart';
import 'ui_common.dart';

enum TelecomOperator {
  smart,
  cellcard,
  metfone,
}

class MobileTopUpScreen extends StatefulWidget {
  // Kept so existing callers (Home screen) still compile.
  // The screen now reads real balances from AccountStore.
  final String? accountNumber;
  final String? balance;

  const MobileTopUpScreen({
    super.key,
    this.accountNumber,
    this.balance,
  });

  @override
  State<MobileTopUpScreen> createState() => _MobileTopUpScreenState();
}

class _MobileTopUpScreenState extends State<MobileTopUpScreen> {
  final AccountStore _store = AccountStore.instance;

  int _selectedTab = 0; // 0: ស្វ័យប្រវត្តិ, 1: ទិញកាត
  final TextEditingController _phoneController =
      TextEditingController(text: '098 965 454');
  final TextEditingController _amountController = TextEditingController();

  double? _selectedQuickAmount;
  int? _selectedPackageIndex;
  bool _showMoreAmounts = false;
  bool _isLoading = false;

  Account? _fromAccount;

  // Same accounts as the Accounts screen and the Own Transfer screen
  List<Account> get _allAccounts => _store.accounts;

  @override
  void initState() {
    super.initState();

    final all = _allAccounts;
    if (all.isNotEmpty) {
      // Default: a dollar account that has money, else any account with money
      _fromAccount = all.firstWhere(
        (a) => a.currency == 'USD' && a.balance > 0,
        orElse: () => all.firstWhere(
          (a) => a.balance > 0,
          orElse: () => all.first,
        ),
      );
    }

    _phoneController.addListener(() {
      if (!mounted) return;
      setState(() {
        // A different operator can have fewer packages; drop a stale selection
        if (_selectedPackageIndex != null &&
            _selectedPackageIndex! >= _currentDataPackages.length) {
          _selectedPackageIndex = null;
        }
      });
    });
  }

  TelecomOperator get _detectedOperator {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (clean.startsWith('012') ||
        clean.startsWith('011') ||
        clean.startsWith('014') ||
        clean.startsWith('017') ||
        clean.startsWith('061') ||
        clean.startsWith('076') ||
        clean.startsWith('077') ||
        clean.startsWith('078') ||
        clean.startsWith('079') ||
        clean.startsWith('085') ||
        clean.startsWith('089') ||
        clean.startsWith('092') ||
        clean.startsWith('095') ||
        clean.startsWith('099')) {
      return TelecomOperator.cellcard;
    }

    if (clean.startsWith('097') ||
        clean.startsWith('088') ||
        clean.startsWith('031') ||
        clean.startsWith('060') ||
        clean.startsWith('066') ||
        clean.startsWith('067') ||
        clean.startsWith('068') ||
        clean.startsWith('071') ||
        clean.startsWith('090')) {
      return TelecomOperator.metfone;
    }

    return TelecomOperator.smart;
  }

  String get _operatorName {
    switch (_detectedOperator) {
      case TelecomOperator.cellcard:
        return 'Cellcard';
      case TelecomOperator.metfone:
        return 'Metfone';
      case TelecomOperator.smart:
        return 'Smart';
    }
  }

  List<Map<String, dynamic>> get _currentDataPackages {
    switch (_detectedOperator) {
      case TelecomOperator.cellcard:
        return [
          {
            'title': 'Cellcard Play 1.5',
            'bannerColor': const Color(0xFFF99D1C),
            'data': '20GB',
            'priceInfo': '1.5\$ / 7days',
            'price': 1.5,
            'feature': 'Unlimited Play',
          },
          {
            'title': 'Cellcard Big Love 2',
            'bannerColor': const Color(0xFFEA580C),
            'data': '35GB',
            'priceInfo': '2\$ / 7days',
            'price': 2.0,
            'feature': 'Extra Night Data',
          },
          {
            'title': 'Cellcard Super 6',
            'bannerColor': const Color(0xFFC2410C),
            'data': '100GB',
            'priceInfo': '6\$ / 30days',
            'price': 6.0,
            'feature': 'High Speed Data',
          },
        ];
      case TelecomOperator.metfone:
        return [
          {
            'title': 'Metfone MI 1.5',
            'bannerColor': const Color(0xFFE50019),
            'data': '20GB',
            'priceInfo': '1.5\$ / 7days',
            'price': 1.5,
            'feature': 'TikTok + YouTube Free',
          },
          {
            'title': 'Metfone 4G Plus 2',
            'bannerColor': const Color(0xFFB91C1C),
            'data': '32GB',
            'priceInfo': '2\$ / 7days',
            'price': 2.0,
            'feature': 'High Speed 4G',
          },
          {
            'title': 'Metfone Super 6',
            'bannerColor': const Color(0xFF991B1B),
            'data': '95GB',
            'priceInfo': '6\$ / 30days',
            'price': 6.0,
            'feature': 'Unlimited Social',
          },
        ];
      case TelecomOperator.smart:
        return [
          {
            'title': 'Smart 5G Data 1.5',
            'bannerColor': const Color(0xFFEAB308),
            'data': '20GB',
            'priceInfo': '1.5\$ / 7days',
            'price': 1.5,
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 2',
            'bannerColor': const Color(0xFF059669),
            'data': '30GB',
            'priceInfo': '2\$ / 7days',
            'price': 2.0,
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 6',
            'bannerColor': const Color(0xFFE11D48),
            'data': '90GB',
            'priceInfo': '6\$ / 30days',
            'price': 6.0,
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 10',
            'bannerColor': const Color(0xFF2563EB),
            'data': '150GB',
            'priceInfo': '10\$ / 30days',
            'price': 10.0,
            'feature': 'Cybersecurity + Call',
          },
        ];
    }
  }

  final List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 1.0, 'display': '1', 'days': '7 ថ្ងៃ'},
    {'amount': 2.0, 'display': '2', 'days': '15 ថ្ងៃ'},
    {'amount': 3.25, 'display': '3.25', 'days': '15 ថ្ងៃ'},
    {'amount': 5.0, 'display': '5', 'days': '30 ថ្ងៃ'},
    {'amount': 10.0, 'display': '10', 'days': '60 ថ្ងៃ'},
    {'amount': 20.0, 'display': '20', 'days': '90 ថ្ងៃ'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ---------- Choose which account pays ----------
  Future<void> _pickAccount() async {
    final options = _allAccounts;
    if (options.isEmpty) {
      _showErrorSnackBar('គ្មានគណនី');
      return;
    }

    final picked = await showModalBottomSheet<Account>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text(
              'ជ្រើសរើសគណនី',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final a in options)
                    ListTile(
                      leading: Icon(
                        a.kind == AccountKind.wallet
                            ? Icons.account_balance_wallet_outlined
                            : Icons.account_balance_outlined,
                        color: const Color(0xFF13253E),
                      ),
                      title: Text(
                        a.number,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(a.name),
                      trailing: Text(
                        '${a.balanceText} ${a.symbol}',
                        style: const TextStyle(
                          color: Color(0xFF2F4FA3),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      selected: _fromAccount?.id == a.id,
                      onTap: () => Navigator.pop(ctx, a),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _fromAccount = picked);
    }
  }

  // ---------- Pay: deduct from chosen account + save to history ----------
  Future<void> _processTopUp() async {
    FocusScope.of(context).unfocus();

    final from = _fromAccount;
    if (from == null) {
      _showErrorSnackBar('សូមជ្រើសរើសគណនី');
      return;
    }

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('សូមបញ្ចូលលេខទូរស័ព្ទ');
      return;
    }

    double amount = 0.0;
    String packageName = '';

    final packages = _currentDataPackages;
    final pkgIndex = _selectedPackageIndex;
    if (pkgIndex != null && pkgIndex < packages.length) {
      amount = (packages[pkgIndex]['price'] as num).toDouble();
      packageName = packages[pkgIndex]['title'] as String;
    } else {
      final amountText = _amountController.text.trim();
      if (amountText.isEmpty) {
        _showErrorSnackBar('សូមបញ្ចូលចំនួនទឹកប្រាក់ ឬជ្រើសរើសកញ្ចប់');
        return;
      }
      amount = double.tryParse(amountText) ?? 0.0;
      if (amount < 1 || amount > 50) {
        _showErrorSnackBar('ចំនួនទឹកប្រាក់ត្រូវនៅចន្លោះ \$1 ដល់ \$50');
        return;
      }
    }

    if (_store.topUpCost(from, amount) > from.balance) {
      _showErrorSnackBar('ទឹកប្រាក់ក្នុងគណនីមិនគ្រប់គ្រាន់ទេ!');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final error = _store.topUp(
      from: from,
      amount: amount,
      phone: phoneNumber,
      operatorName: _operatorName,
      packageName: packageName,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      _showErrorSnackBar(error);
      return;
    }

    _showSuccess(from, amount, phoneNumber, packageName);
  }

  void _showSuccess(
    Account from,
    double amount,
    String phone,
    String packageName,
  ) {
    final shown = amount.truncateToDouble() == amount
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final cost = _store.topUpCost(from, amount);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('ជោគជ័យ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _kv('ទៅលេខ', phone),
            _kv('ចំនួន', '\$$shown'),
            if (from.currency == 'KHR')
              _kv('ត្រូវកាត់ពីគណនី', '${AccountStore.format(cost, 'KHR')} ៛'),
            if (packageName.isNotEmpty) _kv('កញ្ចប់', packageName),
            _kv('ពីគណនី', from.number),
            _kv('សមតុល្យនៅសល់', '${from.balanceText} ${from.symbol}'),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                slideRoute(TransactionHistoryScreen(accountId: from.id)),
              );
            },
            child: const Text(
              'មើលប្រវត្តិ',
              style: TextStyle(color: Color(0xFF2F4FA3)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text(
              'យល់ព្រម',
              style: TextStyle(
                color: Color(0xFF13253E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(k, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13253E), // ACLEDA Deep Navy
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildCustomAppBar(),
            _buildOperatorHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSegmentedTab(),
                        const SizedBox(height: 18),
                        _buildAccountSelector(),
                        if (_fromAccount?.currency == 'KHR')
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              'អត្រាប្តូរប្រាក់: 1\$ = ៛${AccountStore.format(AccountStore.khrPerUsd, 'KHR')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        _buildPhoneNumberField(),
                        const SizedBox(height: 20),
                        const Text(
                          'សម្រាប់ទឹកប្រាក់ក្នុងគណនីគោល',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildCustomAmountField(),
                        const SizedBox(height: 12),
                        _buildQuickAmountRow(),
                        const SizedBox(height: 10),
                        Center(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showMoreAmounts = !_showMoreAmounts;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _showMoreAmounts
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFFB58525),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'សម្រាប់ភ្ជាប់កញ្ចប់',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDataPackageList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Navigator.maybePop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFF263D5C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Row(
                children: [
                  Text(
                    'បញ្ចូលលុយទូរស័ព្ទ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: CustomPaint(
              painter: _AcledaBirdLogoPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatorHeader() {
    final op = _detectedOperator;
    String name;
    String assetPath;
    Color brandColor;

    switch (op) {
      case TelecomOperator.cellcard:
        name = 'Cellcard';
        assetPath = 'assets/cellcard.png';
        brandColor = const Color(0xFFF99D1C);
        break;
      case TelecomOperator.metfone:
        name = 'Metfone';
        assetPath = 'assets/metfone.png';
        brandColor = const Color(0xFFE50019);
        break;
      case TelecomOperator.smart:
        name = 'Smart';
        assetPath = 'assets/smart.png';
        brandColor = const Color(0xFF039855);
        break;
    }

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: brandColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            name,
            key: ValueKey(name),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEFF3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0
                      ? const Color(0xFF132A46)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'ស្វ័យប្រវត្តិ',
                  style: TextStyle(
                    color: _selectedTab == 0
                        ? Colors.white
                        : const Color(0xFF475569),
                    fontWeight: _selectedTab == 0
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1
                      ? const Color(0xFF132A46)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'ទិញកាត',
                  style: TextStyle(
                    color: _selectedTab == 1
                        ? Colors.white
                        : const Color(0xFF475569),
                    fontWeight: _selectedTab == 1
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tap to choose which account pays
  Widget _buildAccountSelector() {
    final acc = _fromAccount;
    return InkWell(
      onTap: _pickAccount,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ពីគណនី',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  acc?.number ?? 'ជ្រើសរើសគណនី',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  acc == null
                      ? ''
                      : '${acc.balanceText} ${acc.currencyWord}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFFC48B2B),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'លេខទូរស័ព្ទ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    hintText: 'បញ្ចូលលេខទូរស័ព្ទ',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.contact_phone_outlined,
                  color: Color(0xFFC48B2B),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAmountField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedQuickAmount = null;
                  _selectedPackageIndex = null;
                });
              },
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'ចំនួនទឹកប្រាក់ (\$1 - \$50)',
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const Text(
            '\$',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountRow() {
    final list =
        _showMoreAmounts ? _quickAmounts : _quickAmounts.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.map((item) {
            final double amount = (item['amount'] as num).toDouble();
            final String display = item['display'] as String;
            final String days = item['days'] as String;
            final isSelected = _selectedQuickAmount == amount;
            final itemWidth = (constraints.maxWidth - 20) / 3;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedQuickAmount = amount;
                  _amountController.text = display;
                  _selectedPackageIndex = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '\$',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            display,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            days,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDataPackageList() {
    final packages = _currentDataPackages;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: packages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pkg = packages[index];
          final isSelected = _selectedPackageIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPackageIndex = index;
                _selectedQuickAmount = null;
                _amountController.clear();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: pkg['bannerColor'] as Color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      pkg['title'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              pkg['data'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pkg['priceInfo'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pkg['feature'] as String,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActionButton() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF13253E),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processTopUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE5A93C),
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'យល់ព្រម',
                    style: TextStyle(
                      color: Color(0xFFE5A93C),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AcledaBirdLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5A93C)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.2);
    path.quadraticBezierTo(
        size.width * 0.5, 0, size.width * 0.95, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.5,
        size.width * 0.95, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.7,
        size.width * 0.2, size.height * 0.95);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.5,
        size.width * 0.1, size.height * 0.2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}