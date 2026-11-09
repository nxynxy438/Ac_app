import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account_store.dart';
import 'accounts_screen.dart';
import 'transaction_history.dart';
import 'ui_common.dart';

class OwnTransferScreen extends StatefulWidget {
  const OwnTransferScreen({super.key});

  @override
  State<OwnTransferScreen> createState() => _OwnTransferScreenState();
}

class _OwnTransferScreenState extends State<OwnTransferScreen> {
  final AccountStore _store = AccountStore.instance;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _purposeCtrl = TextEditingController();

  Account? _from;
  Account? _to;
  bool _purposeOn = false;
  bool _scheduleOn = false;
  DateTime? _scheduleDate;

  @override
  void initState() {
    super.initState();
    _from = _store.accounts.firstWhere(
      (a) => a.balance > 0,
      orElse: () => _store.accounts.first,
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _purposeCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {Color color = AppColors.red}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _pickAccount({required bool isFrom}) async {
    final List<Account> options;
    if (isFrom) {
      options = _store.accounts;
    } else {
      if (_from == null) {
        _toast('សូមជ្រើសរើសគណនីដែលត្រូវផ្ទេរពីសិន');
        return;
      }
      options = _store.destinationsFor(_from!);
    }
    if (options.isEmpty) {
      _toast('គ្មានគណនីផ្សេងដែលមានរូបិយប័ណ្ណដូចគ្នា');
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
            Text(
              isFrom ? 'ពីគណនី' : 'ទៅគណនី',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
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
                        color: AppColors.navy,
                      ),
                      title: Text(
                        a.number,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(a.name),
                      trailing: Text(
                        '${a.balanceText} ${a.symbol}',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to != null &&
            (_to!.id == picked.id || _to!.currency != picked.currency)) {
          _to = null;
        }
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _pickScheduleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate ?? now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final from = _from;
    final to = _to;
    if (from == null) {
      _toast('សូមជ្រើសរើសគណនីដែលត្រូវផ្ទេរពី');
      return;
    }
    if (to == null) {
      _toast('សូមជ្រើសរើសគណនីដែលត្រូវផ្ទេរទៅ');
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _toast('សូមបញ្ចូលចំនួនទឹកប្រាក់');
      return;
    }
    if (_scheduleOn && _scheduleDate == null) {
      _toast('សូមជ្រើសរើសកាលបរិច្ឆេទផ្ទេរប្រាក់');
      return;
    }

    Navigator.push(
      context,
      slideRoute(_TransferConfirmScreen(
        from: from,
        to: to,
        amount: amount,
        purpose: _purposeOn ? _purposeCtrl.text.trim() : '',
        scheduledFor: _scheduleOn ? _scheduleDate : null,
      )),
    );
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
                      const Spacer(),
                      const AppLogo(size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildHeroIcon(),
                const SizedBox(height: 22),
              ],
            ),
          ),
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
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildHeroIcon() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF4A4FB0),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.swap_horiz_rounded,
              color: Colors.white, size: 54),
        ),
        const SizedBox(height: 12),
        const Text(
          'គណនីផ្ទាល់ខ្លួន',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final symbol = _from?.symbol ?? r'$';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectField(
          floatingLabel: 'ពីគណនី',
          placeholder: 'ពីគណនី',
          account: _from,
          onTap: () => _pickAccount(isFrom: true),
        ),
        const SizedBox(height: 18),
        _selectField(
          floatingLabel: 'ទៅគណនី',
          placeholder: 'ទៅគណនី',
          account: _to,
          onTap: () => _pickAccount(isFrom: false),
        ),
        const SizedBox(height: 18),
        Container(
          height: 62,
          padding: const EdgeInsets.only(left: 16, right: 8),
          decoration: _fieldBox(),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'ចំនួនទឹកប្រាក់',
                    hintStyle: TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Container(
                width: 48,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _toggleRow(
          'គោលបំណង',
          _purposeOn,
          (v) => setState(() => _purposeOn = v),
        ),
        if (_purposeOn) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: _fieldBox(),
            child: TextField(
              controller: _purposeCtrl,
              maxLength: 60,
              style: const TextStyle(color: AppColors.text, fontSize: 16),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'បញ្ចូលគោលបំណង',
                hintStyle: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _toggleRow(
          'ការផ្ទេរប្រាក់តាមកាលវិភាគ',
          _scheduleOn,
          (v) => setState(() {
            _scheduleOn = v;
            if (!v) _scheduleDate = null;
          }),
        ),
        if (_scheduleOn) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickScheduleDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: _fieldBox(),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _scheduleDate == null
                          ? 'ជ្រើសរើសកាលបរិច្ឆេទ'
                          : _fmtDay(_scheduleDate!),
                      style: TextStyle(
                        color: _scheduleDate == null
                            ? AppColors.muted
                            : AppColors.text,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_month_outlined,
                      color: AppColors.gold),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _fieldBox() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      );

  Widget _selectField({
    required String floatingLabel,
    required String placeholder,
    required Account? account,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 82,
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: _fieldBox(),
            child: Row(
              children: [
                Expanded(
                  child: account == null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            placeholder,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 17,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              account.number,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${account.balanceText} ${account.currencyWord}',
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 62,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.gold, size: 34),
                ),
              ],
            ),
          ),
          if (account != null)
            Positioned(
              left: 12,
              top: -9,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  floatingLabel,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: const WidgetStatePropertyAll(AppColors.navy),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? const Color(0xFFE9D9A6)
                : Colors.white,
          ),
          trackOutlineColor: const WidgetStatePropertyAll(AppColors.border),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.navy,
        child: InkWell(
          onTap: _submit,
          child: const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'យល់ព្រម',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ==========================================
// CONFIRMATION SCREEN
// ==========================================
class _TransferConfirmScreen extends StatelessWidget {
  final Account from;
  final Account to;
  final double amount;
  final String purpose;
  final DateTime? scheduledFor;

  const _TransferConfirmScreen({
    required this.from,
    required this.to,
    required this.amount,
    required this.purpose,
    required this.scheduledFor,
  });

  void _confirmTransfer(BuildContext context) {
    final error = AccountStore.instance.transferOwn(
      from: from,
      to: to,
      amount: amount,
      purpose: purpose,
      scheduledFor: scheduledFor,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.red),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      slideRoute(_TransferReceiptScreen(
        from: from,
        to: to,
        amount: amount,
        scheduledFor: scheduledFor,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  const Spacer(),
                  const AppLogo(size: 32),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'សូមផ្ទៀងផ្ទាត់ប្រតិបត្តិការ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E9F6E),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'PR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phon Rany',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${to.number} (${to.currencyWord})',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ចំនួនទឹកប្រាក់',
                        style: TextStyle(color: AppColors.muted, fontSize: 16),
                      ),
                      Text(
                        '${AccountStore.format(amount, from.currency)} ${from.symbol}',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), thickness: 1, height: 1),
                  const SizedBox(height: 18),
                  const Text(
                    'ផ្ទេរប្រាក់ពី',
                    style: TextStyle(color: AppColors.muted, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PHORN RANY',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${from.number} (${from.currencyWord})',
                    style: const TextStyle(color: AppColors.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: AppColors.navy,
              child: InkWell(
                onTap: () => _confirmTransfer(context),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Center(
                      child: Text(
                        'បញ្ជាក់',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
}

// ==========================================
// SUCCESS RECEIPT SCREEN
// ==========================================
class _TransferReceiptScreen extends StatelessWidget {
  final Account from;
  final Account to;
  final double amount;
  final DateTime? scheduledFor;

  const _TransferReceiptScreen({
    required this.from,
    required this.to,
    required this.amount,
    required this.scheduledFor,
  });

  @override
  Widget build(BuildContext context) {
    final nowStr = AccountStore.formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  AppLogo(size: 34),
                  SizedBox(width: 8),
                  Text(
                    'អេស៊ីលីដា',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B3052),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFFF2C94C),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ជោគជ័យ',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E9F6E),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'PR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ផ្ទេរទៅ',
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                              const Text(
                                'Phon Rany',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${AccountStore.format(amount, from.currency)} ${from.symbol}',
                                style: const TextStyle(
                                  color: Color(0xFFD97706),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE5E7EB), thickness: 1, height: 1),
                    const SizedBox(height: 16),
                    _receiptRow('ពីគណនី', 'PHORN RANY'),
                    _receiptRow('លេខគណនី', '${from.number} (${from.currencyWord})'),
                    _receiptRow('ទឹកប្រាក់កាត់ចេញ', '-${AccountStore.format(amount, from.currency)} ${from.symbol}', isRed: true),
                    _receiptRow('ទៅគណនី', 'Phon Rany'),
                    _receiptRow('លេខគណនី', '${to.number} (${to.currencyWord})'),
                    _receiptRow('លេខយោង', '63131392112'),
                    _receiptRow('កាលបរិច្ឆេទ', nowStr),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.navy),
                          SizedBox(width: 6),
                          Text(
                            'កំណត់កាលវិភាគ',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: AppColors.navy,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
                child: Row(
                  children: [
                    _bottomAction(
                      icon: Icons.home_rounded,
                      label: 'ទំព័រដើម',
                      onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                    ),
                    _bottomAction(
                      icon: Icons.refresh_rounded,
                      label: 'ផ្ទេរម្ដងទៀត',
                      onTap: () => Navigator.pop(context),
                    ),
                    _bottomAction(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'គណនី',
                      onTap: () => Navigator.pushReplacement(
                        context,
                        slideRoute(const AccountsScreen()),
                      ),
                    ),
                    _bottomAction(
                      icon: Icons.ios_share_rounded,
                      label: 'ចែករំលែក',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('បានចែករំលែកបង្កាន់ដៃ')),
                      ),
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

  Widget _receiptRow(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isRed ? AppColors.red : AppColors.text,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}