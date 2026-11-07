import 'package:flutter/material.dart';
import 'user_session.dart';

enum TelecomOperator {
  smart,
  cellcard,
  metfone,
}

class MobileTopUpScreen extends StatefulWidget {
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
  int _selectedTab = 0; // 0: ស្វ័យប្រវត្តិ, 1: ទិញកាត
  final TextEditingController _phoneController =
      TextEditingController(text: '098 965 454');
  final TextEditingController _amountController = TextEditingController();

  double? _selectedQuickAmount;
  int? _selectedPackageIndex;
  bool _showMoreAmounts = false;

  String get _displayAccountNumber {
    if (widget.accountNumber != null && widget.accountNumber!.isNotEmpty) {
      return widget.accountNumber!;
    }
    final s = UserSession.instance;
    if (s.accountNumber.isNotEmpty) {
      return s.accountNumber;
    }
    return '3863-05323191-14';
  }

  String get _displayBalance {
    if (widget.balance != null && widget.balance!.isNotEmpty) {
      return widget.balance!;
    }
    final s = UserSession.instance;
    return '${s.balance.toStringAsFixed(2)} ដុល្លារ';
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {});
    });
  }

  TelecomOperator get _detectedOperator {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');

    // Cellcard: 012 (and all Cellcard prefixes: 011, 014, 017, 061, 076, 077, 078, 079, 085, 089, 092, 095, 099)
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

    // Metfone: 097, 088 (and all Metfone prefixes: 031, 060, 066, 067, 068, 071, 090)
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

    // Smart: 096, 098, 081, 010 (and all Smart prefixes: 015, 016, 069, 070, 086, 087, 093)
    if (clean.startsWith('096') ||
        clean.startsWith('098') ||
        clean.startsWith('081') ||
        clean.startsWith('010') ||
        clean.startsWith('015') ||
        clean.startsWith('016') ||
        clean.startsWith('069') ||
        clean.startsWith('070') ||
        clean.startsWith('086') ||
        clean.startsWith('087') ||
        clean.startsWith('093')) {
      return TelecomOperator.smart;
    }

    // Default operator
    return TelecomOperator.smart;
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
            'feature': 'Unlimited Play',
          },
          {
            'title': 'Cellcard Big Love 2',
            'bannerColor': const Color(0xFFEA580C),
            'data': '35GB',
            'priceInfo': '2\$ / 7days',
            'feature': 'Extra Night Data',
          },
          {
            'title': 'Cellcard Super 6',
            'bannerColor': const Color(0xFFC2410C),
            'data': '100GB',
            'priceInfo': '6\$ / 30days',
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
            'feature': 'TikTok + YouTube Free',
          },
          {
            'title': 'Metfone 4G Plus 2',
            'bannerColor': const Color(0xFFB91C1C),
            'data': '32GB',
            'priceInfo': '2\$ / 7days',
            'feature': 'High Speed 4G',
          },
          {
            'title': 'Metfone Super 6',
            'bannerColor': const Color(0xFF991B1B),
            'data': '95GB',
            'priceInfo': '6\$ / 30days',
            'feature': 'Unlimited Social',
          },
        ];
      case TelecomOperator.smart:
      default:
        return [
          {
            'title': 'Smart 5G Data 1.5',
            'bannerColor': const Color(0xFFEAB308),
            'data': '20GB',
            'priceInfo': '1.5\$ / 7days',
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 2',
            'bannerColor': const Color(0xFF059669),
            'data': '30GB',
            'priceInfo': '2\$ / 7days',
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 6',
            'bannerColor': const Color(0xFFE11D48),
            'data': '90GB',
            'priceInfo': '6\$ / 30days',
            'feature': 'Cybersecurity',
          },
          {
            'title': 'Smart 5G Data 10',
            'bannerColor': const Color(0xFF2563EB),
            'data': '150GB',
            'priceInfo': '10\$ / 30days',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13253E), // ACLEDA Deep Navy
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            _buildCustomAppBar(),

            // Telecom Operator Logo Header
            _buildOperatorHeader(),
            const SizedBox(height: 16),

            // White Rounded Bottom Card (Scrollable Body)
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
                        // Segmented Tab Toggle (ស្វ័យប្រវត្តិ / ទិញកាត)
                        _buildSegmentedTab(),
                        const SizedBox(height: 18),

                        // Source Account Card / Selector
                        _buildAccountSelector(),
                        const SizedBox(height: 14),

                        // Phone Number Input
                        _buildPhoneNumberField(),
                        const SizedBox(height: 20),

                        // Section 1: Main Balance Top Up
                        const Text(
                          'សម្រាប់ទឹកប្រាក់ក្នុងគណនីគោល',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Custom Amount Field
                        _buildCustomAmountField(),
                        const SizedBox(height: 12),

                        // Preset Quick Amounts Grid
                        _buildQuickAmountRow(),
                        const SizedBox(height: 10),

                        // Expand/Collapse Chevron Button
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

                        // Section 2: Data Package Subscription
                        const Text(
                          'សម្រាប់ភ្ជាប់កញ្ចប់',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Horizontal Data Package List
                        _buildDataPackageList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Confirmation Button
            _buildBottomActionButton(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Circle Back Button
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

              // Title with Info Icon
              Row(
                children: const [
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

          // ACLEDA Golden Mythic Bird Logo Icon
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
      default:
        name = 'Smart';
        assetPath = 'assets/smart.png';
        brandColor = const Color(0xFF039855);
        break;
    }

    return Column(
      children: [
        // Operator Circular Avatar with animated transition
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
                color: Colors.black.withOpacity(0.25),
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
          // Tab 1: ស្វ័យប្រវត្តិ
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
                            color: Colors.black.withOpacity(0.12),
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
          // Tab 2: ទិញកាត
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
                            color: Colors.black.withOpacity(0.12),
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

  Widget _buildAccountSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label
          const Text(
            'ពីគណនី',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Account Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayAccountNumber,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _displayBalance,
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
            color: Color(0xFFC48B2B), // ACLEDA Gold
            size: 26,
          ),
        ],
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
                  onChanged: (val) {
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                    hintText: 'បញ្ចូលលេខទូរស័ព្ទ',
                  ),
                ),
              ),
              // Contact Picker Icon Pill
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.contact_phone_outlined,
                  color: Color(0xFFC48B2B), // ACLEDA Gold
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
    final list = _showMoreAmounts ? _quickAmounts : _quickAmounts.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.map((item) {
            final double amount = item['amount'] as double;
            final isSelected = _selectedQuickAmount == amount;
            final itemWidth = (constraints.maxWidth - 20) / 3;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedQuickAmount = amount;
                  _amountController.text = item['display'];
                  _selectedPackageIndex = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF1E3A8A)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Currency Circle
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
                    // Amount & Validity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            item['display'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['days'],
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
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _currentDataPackages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final pkg = _currentDataPackages[index];
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner with Title
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
                      pkg['title'],
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Body Content
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
                              pkg['data'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pkg['priceInfo'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pkg['feature'],
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
      color: const Color(0xFF13253E), // ACLEDA Deep Navy
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'កំពុងដំណើរការបញ្ចូលលុយសម្រាប់ ${_phoneController.text}...',
                  ),
                  backgroundColor: const Color(0xFF13253E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'យល់ព្រម',
              style: TextStyle(
                color: Color(0xFFE5A93C), // ACLEDA Gold
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

// Custom Painter for ACLEDA Golden Mythic Bird Logo Icon
class _AcledaBirdLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5A93C)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.5, 0, size.width * 0.95, size.height * 0.15);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.5, size.width * 0.95, size.height * 0.9);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.7, size.width * 0.2, size.height * 0.95);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.5, size.width * 0.1, size.height * 0.2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
