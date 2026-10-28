import 'package:flutter/material.dart';
import 'otp_screen.dart'; // Import OTP screen or your next destination

class RegisterDetailsScreen extends StatefulWidget {
  final String email;
  final String selectedDocument;

  const RegisterDetailsScreen({
    super.key,
    required this.email,
    required this.selectedDocument,
  });

  @override
  State<RegisterDetailsScreen> createState() => _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends State<RegisterDetailsScreen> {
  final List<String> documents = [
    'National Identity Card',
    'Passport',
    'Family Book',
    'ACLEDA Bank ID Card',
    'Monk Identification Card',
    'Birth Certificate',
    'Identity Certificate with Photo',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF142238), // Exact dark navy background
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'REGISTER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(Icons.eco, color: Colors.amber, size: 24),
                ],
              ),
            ),

            // Top Space
            const Spacer(flex: 1),

            // Main Document Bottom Sheet
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF1B2E46), // Header sheet color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // Grey drag handle bar
                  Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Banner: DOCUMENT FOR REGISTER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: const Color(0xFF1B2E46),
                    child: const Center(
                      child: Text(
                        'DOCUMENT FOR REGISTER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // White list container for document options
                  Container(
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(documents.length, (index) {
                        final docName = documents[index];
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Selected: $docName"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                color: Colors.white,
                                child: Text(
                                  docName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF2C3E50),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // Divider line matching image style
                            if (index < documents.length - 1)
                              Container(
                                height: 3,
                                color: const Color(0xFFF0F2F5),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),

                  // Bottom Home Indicator Bar spacing (iOS style)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Center(
                      child: Container(
                        width: 134,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}