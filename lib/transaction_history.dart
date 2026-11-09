import 'package:flutter/material.dart';

import 'account_store.dart';
import 'ui_common.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String? accountId;
  const TransactionHistoryScreen({super.key, this.accountId});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final AccountStore _store = AccountStore.instance;
  int _tab = 0; // 0 = ប្រតិបត្តិការ (Transactions), 1 = ព័ត៌មានធនាគារ (Bank Info)

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

  List<TransactionRecord> get _records {
    final id = widget.accountId;
    if (id == null) return _store.history;
    return _store.history.where((t) => t.fromId == id || t.toId == id).toList();
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;

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
                        'ការជូនដំណឹង',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const AppLogo(size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildTabs(),
                const SizedBox(height: 16),
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
                child: _tab == 0
                    ? (records.isEmpty ? _buildEmpty() : _buildList(records))
                    : _buildBankInfoPlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF13233D),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = 0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == 0 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'ប្រតិបត្តិការ',
                    style: TextStyle(
                      color: _tab == 0 ? AppColors.navy : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = 1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tab == 1 ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'ព័ត៌មានធនាគារ',
                    style: TextStyle(
                      color: _tab == 1 ? AppColors.navy : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined, color: Color(0xFFB8BFCC), size: 64),
          SizedBox(height: 12),
          Text(
            'មិនទាន់មានការជូនដំណឹង',
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TransactionRecord> records) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _notificationCard(records[i]),
    );
  }

  Widget _notificationCard(TransactionRecord t) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLogo(size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACLEDA Mobile',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatNotificationTime(t.date),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ប្រាក់ចំនួន ${AccountStore.format(t.amount, t.currency)} ${t.symbol} បានផ្ទេរទៅ ${t.toName} ចេញពីគណនី ${t.fromNumber}។ លេខយោង ${t.id}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankInfoPlaceholder() {
    return const Center(
      child: Text(
        'គ្មានព័ត៌មានធនាគារថ្មី',
        style: TextStyle(color: AppColors.muted, fontSize: 16),
      ),
    );
  }

  String _formatNotificationTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)} វិច្ឆិកា ${d.year} | ${two(d.hour)}:${two(d.minute)} ល្ងាច';
  }
}