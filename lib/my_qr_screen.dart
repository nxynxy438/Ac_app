import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'user_session.dart';
import 'account_store.dart';

class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  // Track selected currency state: true = KHR, false = USD
  bool _isKhrSelected = true;

  // Dynamically resolve information with safe fallbacks matching your identity data
  String get accountName {
    final session = UserSession.instance;
    return session.firstName.isNotEmpty && session.lastName.isNotEmpty
        ? '${session.firstName} ${session.lastName}'.toUpperCase()
        : 'PHORN RANY';
  }

  String get accountNumber {
    final session = UserSession.instance;
    return session.accountNumber.isNotEmpty 
        ? session.accountNumber 
        : '010 349 035';
  }

  double get balanceKHR {
    final store = AccountStore.instance;
    return store.totalKhr > 0 ? store.totalKhr : 400000.0;
  }

  double get balanceUSD {
    final store = AccountStore.instance;
    return store.totalUsd > 0 ? store.totalUsd : 150.25;
  }

  // Generates payload tailored to the currently highlighted account selection
  String _generateQrPayload() {
    final Map<String, dynamic> qrPayloadMap = {
      'type': 'bank_account_balance',
      'name': accountName,
      'accountNo': accountNumber,
      'selectedCurrency': _isKhrSelected ? 'KHR' : 'USD',
      'activeBalance': _isKhrSelected ? balanceKHR : balanceUSD,
      'balances': {
        'KHR': balanceKHR,
        'USD': balanceUSD,
      },
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(qrPayloadMap);
  }

  @override
  Widget build(BuildContext context) {
    String qrStringData = _generateQrPayload();

    return Scaffold(
      backgroundColor: const Color(0xFF132A5A), // Genuine deep blue Acleda app theme background
      appBar: AppBar(
        title: const Text(
          "KHQR របស់ខ្ញុំ", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // White Card Layout representing Bakong KHQR Matrix
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Red KHQR Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE52326),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "KHQR", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 1.2)
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User Account Holder Name
                    Text(
                      accountName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F1F1F), letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 10),
                    
                    // Decorative Dashed Divider Line
                    Row(
                      children: List.generate(30, (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300,
                          height: 1,
                        ),
                      )),
                    ),
                    const SizedBox(height: 20),
                    
                    // QR Core Implementation Box with center embedded logo space
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: qrStringData,
                          version: QrVersions.auto,
                          size: 230.0,
                          gapless: true,
                          eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                          dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                        ),
                        // Inner Center Red Logo Icon Anchor
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE52326),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.brightness_7, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Account Selection Container (Simulating your Transfer Screen options)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF203B70),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "គណនីទទួលប្រាក់", 
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                    const SizedBox(height: 12),
                    
                    // KHR Selection Option Tile Row
                    GestureDetector(
                      onTap: () => setState(() => _isKhrSelected = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isKhrSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isKhrSelected ? const Color(0xFFC9A548) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isKhrSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _isKhrSelected ? const Color(0xFFC9A548) : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "$accountNumber (រៀល)", 
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                              ),
                            ),
                            Text(
                              "${AccountStore.format(balanceKHR, 'KHR')} ៛", 
                              style: TextStyle(
                                color: _isKhrSelected ? const Color(0xFFC9A548) : Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 15
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // USD Selection Option Tile Row
                    GestureDetector(
                      onTap: () => setState(() => _isKhrSelected = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !_isKhrSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isKhrSelected ? const Color(0xFF5BB5F0) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              !_isKhrSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: !_isKhrSelected ? const Color(0xFF5BB5F0) : Colors.white60,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "$accountNumber (ដុល្លារ)", 
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                              ),
                            ),
                            Text(
                              "\$" + AccountStore.format(balanceUSD, 'USD'), 
                              style: TextStyle(
                                color: !_isKhrSelected ? const Color(0xFF5BB5F0) : Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 15
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Bottom Quick Utility Action Buttons Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(Icons.file_download_outlined, "រក្សាទុក"),
                  _buildActionButton(Icons.label_outline, "កំណត់ចំនួនទឹកប្រាក់"),
                  _buildActionButton(Icons.ios_share, "ចែករំលែក"),
                ],
              ),
              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2),
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
