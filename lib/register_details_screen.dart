import 'package:flutter/material.dart';
import 'register_profile_screen.dart';

class RegisterDetailsScreen extends StatefulWidget {
  final String email;
  final String selectedDocument;

  const RegisterDetailsScreen({
    super.key,
    required this.email,
    this.selectedDocument = '', // optional now, so OtpScreen can omit it
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

  void _onDocumentTap(String docName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterProfileScreen(
          email: widget.email,
          selectedDocument: docName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF142238), // Exact dark navy background
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
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
                  // ACLEDA logo replaces the old leaf icon
                  Image.asset(
                    'assets/Acleda.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.eco, color: Colors.amber, size: 24),
                  ),
                ],
              ),
            ),

            // Fills the remaining space; sheet sits at the bottom and
            // scrolls if the screen is too small (prevents overflow error)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SingleChildScrollView(
                  child: Container(
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
                            color: Colors.grey.shade600.withAlpha(128),
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
                                    onTap: () => _onDocumentTap(docName),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18, horizontal: 16),
                                      color: Colors.transparent,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}