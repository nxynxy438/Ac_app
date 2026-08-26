import 'package:flutter/material.dart';
import 'api_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  bool _isLoading = false;

  Future<void> _handleTransfer() async {
    setState(() {
      _isLoading = true;
    });

    String token = "TEMPORARY_TOKEN_OR_REAL_JWT"; 

    bool success = await ApiService.transferMoney(
      token: token,
      recipientAccount: "ACC-8802",
      amount: 50.0,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transfer successful and saved to database!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Transfer Failed! Check your Node.js terminal logs.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Money')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handleTransfer,
                child: const Text('Send \$50'),
              ),
      ),
    );
  }
}