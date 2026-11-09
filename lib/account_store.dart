import 'package:flutter/foundation.dart';

import 'transaction_sync.dart';

enum AccountKind { wallet, bank }

/// What kind of record a history row is.
enum TransactionType { ownTransfer, topUp }

class Account {
  final String id;
  final String number;
  final String name;
  final String currency; // 'KHR' or 'USD'
  final AccountKind kind;
  double balance;

  Account({
    required this.id,
    required this.number,
    required this.name,
    required this.currency,
    required this.kind,
    required this.balance,
  });

  String get symbol => currency == 'KHR' ? '៛' : r'$';
  String get currencyWord => currency == 'KHR' ? 'រៀល' : 'ដុល្លារ';
  String get balanceText => AccountStore.format(balance, currency);
}

class TransactionRecord {
  final String id;
  final String fromId;
  final String toId;
  final String fromNumber;
  final String toNumber;
  final String fromName;
  final String toName;
  final double amount;
  final String currency;
  final String purpose;
  final DateTime date;
  final DateTime? scheduledFor; // null = done now
  final TransactionType type;

  TransactionRecord({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.fromNumber,
    required this.toNumber,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.currency,
    required this.purpose,
    required this.date,
    this.scheduledFor,
    this.type = TransactionType.ownTransfer,
  });

  bool get isScheduled => scheduledFor != null;
  bool get isTopUp => type == TransactionType.topUp;

  /// Shape the Node backend expects (POST /api/v1/transactions).
  Map<String, dynamic> toJson() => {
        'txnRef': id,
        'type': isTopUp ? 'top_up' : 'own_transfer',
        'fromAccount': fromNumber,
        'fromName': fromName,
        'toAccount': toNumber,
        'toName': toName,
        'amount': amount,
        'currency': currency,
        'purpose': purpose,
        'status': isScheduled ? 'scheduled' : 'completed',
        'scheduledFor': scheduledFor == null
            ? null
            : scheduledFor!.toIso8601String().substring(0, 10),
      };
  String get symbol => currency == 'KHR' ? '៛' : r'$';
}

/// One shared place for balances + history. Every screen reads from here,
/// so a transfer made on the Own Transfer screen shows up on the Accounts
/// screen, the Home screen and the History screen automatically.
class AccountStore extends ChangeNotifier {
  AccountStore._();
  static final AccountStore instance = AccountStore._();

  /// Used only to draw the donut chart on the Accounts screen.
  static const double khrPerUsd = 4100;

  final List<Account> accounts = [
    Account(
      id: 'w-khr',
      number: '010 349 035',
      name: 'គណនីវ៉ាលឡេត រៀល',
      currency: 'KHR',
      kind: AccountKind.wallet,
      balance: 1250000,
    ),
    Account(
      id: 'w-usd',
      number: '010 349 035',
      name: 'គណនីវ៉ាលឡេត ដុល្លារ',
      currency: 'USD',
      kind: AccountKind.wallet,
      balance: 250.00,
    ),
    Account(
      id: 'b-usd',
      number: '2300-05261434-17',
      name: 'គណនីប្រាក់បៀវត្ស ដុល្លារ',
      currency: 'USD',
      kind: AccountKind.bank,
      balance: 1000.00,
    ),
    Account(
      id: 'b-khr',
      number: '2300-05261434-18',
      name: 'គណនីសន្សំ រៀល',
      currency: 'KHR',
      kind: AccountKind.bank,
      balance: 0,
    ),
  ];

  final List<TransactionRecord> _history = [];

  /// Newest first.
  List<TransactionRecord> get history => List.unmodifiable(_history);

  double totalFor(String currency) => accounts
      .where((a) => a.currency == currency)
      .fold(0.0, (sum, a) => sum + a.balance);

  double get totalKhr => totalFor('KHR');
  double get totalUsd => totalFor('USD');

  Account? byId(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Accounts the user can send to from [from] (same currency, not itself).
  List<Account> destinationsFor(Account from) => accounts
      .where((a) => a.id != from.id && a.currency == from.currency)
      .toList();

  /// Moves money between two of the user's own accounts.
  /// Returns null on success, or an error message to show the user.
  String? transferOwn({
    required Account from,
    required Account to,
    required double amount,
    String purpose = '',
    DateTime? scheduledFor,
  }) {
    if (from.id == to.id) return 'សូមជ្រើសរើសគណនីផ្សេងគ្នា';
    if (from.currency != to.currency) {
      return 'អាចផ្ទេរបានតែរវាងគណនីដែលមានរូបិយប័ណ្ណដូចគ្នា';
    }
    if (amount <= 0) return 'ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវ';
    if (scheduledFor == null && amount > from.balance) {
      return 'សមតុល្យមិនគ្រប់គ្រាន់';
    }

    // A scheduled transfer is only recorded; money moves on the chosen date.
    if (scheduledFor == null) {
      from.balance -= amount;
      to.balance += amount;
    }

    _history.insert(
      0,
      TransactionRecord(
        id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        fromId: from.id,
        toId: to.id,
        fromNumber: from.number,
        toNumber: to.number,
        fromName: from.name,
        toName: to.name,
        amount: amount,
        currency: from.currency,
        purpose: purpose,
        date: DateTime.now(),
        scheduledFor: scheduledFor,
      ),
    );
    notifyListeners();
    // Save it on the backend too (Admin > History Transaction)
    TransactionSync.send(_history.first.toJson());
    return null;
  }

  /// What a top-up of [usdAmount] dollars costs in [account]'s own currency.
  /// Dollar accounts pay the same amount; riel accounts pay at [khrPerUsd].
  double topUpCost(Account account, double usdAmount) {
    if (account.currency == 'USD') return usdAmount;
    return (usdAmount * khrPerUsd).roundToDouble();
  }

  /// Pays a phone top-up of [amount] dollars from ANY of the user's accounts
  /// (dollar or riel) and writes it into the history.
  /// Returns null on success, or an error message to show the user.
  String? topUp({
    required Account from,
    required double amount, // in US dollars
    required String phone,
    required String operatorName,
    String packageName = '',
  }) {
    if (amount <= 0) return 'ចំនួនទឹកប្រាក់មិនត្រឹមត្រូវ';

    final cost = topUpCost(from, amount);
    if (cost > from.balance) return 'ទឹកប្រាក់ក្នុងគណនីមិនគ្រប់គ្រាន់ទេ!';

    // keep exactly 2 decimals for dollars so balances never drift
    from.balance = from.currency == 'USD'
        ? double.parse((from.balance - cost).toStringAsFixed(2))
        : from.balance - cost;

    _history.insert(
      0,
      TransactionRecord(
        id: 'TOP-${DateTime.now().millisecondsSinceEpoch}',
        fromId: from.id,
        toId: '',
        fromNumber: from.number,
        toNumber: phone,
        fromName: from.name,
        toName: '$operatorName • $phone',
        amount: cost, // what was really taken from this account
        currency: from.currency,
        purpose: packageName,
        date: DateTime.now(),
        type: TransactionType.topUp,
      ),
    );
    notifyListeners();
    // Save it on the backend too (Admin > History Transaction)
    TransactionSync.send(_history.first.toJson());
    return null;
  }

  /// 1250000 -> "1,250,000" (KHR)   |   1250 -> "1,250.00" (USD)
  static String format(double value, String currency) {
    final text = currency == 'KHR'
        ? value.round().toString()
        : value.toStringAsFixed(2);
    final parts = text.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  /// dd/MM/yyyy HH:mm
  static String formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}