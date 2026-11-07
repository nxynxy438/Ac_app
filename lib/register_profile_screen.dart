import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'register_pin_screen.dart'; // <-- NEW: PIN screen
import 'user_session.dart'; // <-- NEW: saves the data on the device

class RegisterProfileScreen extends StatefulWidget {
  final String email;
  final String selectedDocument;

  const RegisterProfileScreen({
    super.key,
    this.email = '',
    this.selectedDocument = '',
  });

  @override
  State<RegisterProfileScreen> createState() => _RegisterProfileScreenState();
}

class _RegisterProfileScreenState extends State<RegisterProfileScreen> {
  static const Color navy = Color(0xFF1E3050);
  static const Color gold = Color(0xFFC9A24B);
  static const Color pageBg = Color(0xFFF0ECEC);
  static const Color borderGrey = Color(0xFFBDBDBD);
  static const Color hintGrey = Color(0xFF9E9E9E);

  // ⚠️ CHANGE THIS to match the same server address you use for request-otp:
  //   Android emulator : http://10.0.2.2:3000
  //   iOS simulator    : http://localhost:3000
  //   Real phone       : http://<your PC IP>:3000   (e.g. http://192.168.1.5:3000)
  static const String baseUrl = 'http://10.0.2.2:3000';

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();

  File? _profileImage;
  String? _gender;
  DateTime? _birthDate;
  DateTime? _idExpiryDate;
  String? _idType;
  String? _address;
  bool _loading = false;

  final List<String> _genders = ['ប្រុស', 'ស្រី'];
  final List<String> _idTypes = [
  'អត្តសញ្ញាណប័ណ្ណសញ្ជាតិខ្មែរ', // National Identity Card
  'លិខិតឆ្លងដែន',                // Passport
  'សៀវភៅគ្រួសារ',                // Family Book
  'ប័ណ្ណសម្គាល់ខ្លួនបុគ្គលិកធនាគារ អេស៊ីលីដា', // ACLEDA Bank ID Card
  'អត្តសញ្ញាណប័ណ្ណព្រះសង្ឃ',         // Monk Identification Card
  'សំបុត្រកំណើត',                // Birth Certificate
  'លិខិតបញ្ជាក់អត្តសញ្ញាណមានរូបថត',    // Identity Certificate with Photo
  ];
  final List<String> _addresses = [
    'ភ្នំពេញ',
    'កណ្ដាល',
    'សៀមរាប',
    'បាត់ដំបង',
    'កំពត',
    'ព្រះសីហនុ',
    'កំពង់ចាម',
    'កំពង់ឆ្នាំង',
    'កំពង់ស្ពឺ',
    'កំពង់ធំ',
    'កោះកុង',
    'ក្រចេះ',
    'មណ្ឌលគីរី',
    'ព្រៃវែង',
    'ពោធិ៍សាត់',
    'រតនគីរី',
    'ស្ទឹងត្រែង',
    'ស្វាយរៀង',
    'តាកែវ',
    'ត្បូងឃ្មុំ',
    'ឧត្តរមានជ័យ',
    'បន្ទាយមានជ័យ',
    'ប៉ៃលិន',
    'ព្រះវិហារ',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select the document the user tapped on the previous screen
    if (_idTypes.contains(widget.selectedDocument)) {
      _idType = widget.selectedDocument;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _idNumberCtrl.dispose();
    super.dispose();
  }

  // ---------- Pick photo from file explorer ----------
  Future<void> _pickImage() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) {
        _toast('No image selected', Colors.orange);
        return;
      }

      final path = file.path;
      debugPrint('Picked image path: $path');
      if (path == null) {
        _toast('Picker returned no file path', Colors.red);
        return;
      }

      setState(() => _profileImage = File(path));
      _toast('Photo selected: ${path.split(RegExp(r'[\\/]')).last}', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _toast('Could not pick image: $e', Colors.red);
    }
  }

  // ---------- Date picker ----------
  Future<void> _pickDate({
    required DateTime? current,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    DateTime initial = current ?? DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onPicked(picked);
  }

  // Display format: dd/MM/yyyy
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // Server format: yyyy-MM-dd (what MySQL DATE expects)
  String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ---------- Send everything to the Node backend ----------
  Future<void> _submit() async {
    if (_loading) return;

    if (widget.email.trim().isEmpty) {
      _toast('Email is missing. Please go back and verify your email.', Colors.red);
      return;
    }
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _idType == null ||
        _idNumberCtrl.text.trim().isEmpty) {
      _toast('Please fill in all required fields', Colors.red);
      return;
    }

    setState(() => _loading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/profile/register'),
      );

      request.fields.addAll({
        'email': widget.email.trim(),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'gender': _gender ?? '',
        'birthDate': _birthDate != null ? _iso(_birthDate!) : '',
        'idType': _idType!,
        'idNumber': _idNumberCtrl.text.trim(),
        'idExpiryDate': _idExpiryDate != null ? _iso(_idExpiryDate!) : '',
        'address': _address ?? '',
      });

      // The field name "photo" must match upload.single('photo') in app.js
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _profileImage!.path),
        );
      }

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        _toast('Profile saved successfully', Colors.green);

        // NEW: keep everything the user filled in on the device
        await UserSession.instance.saveProfile(
          email: widget.email.trim(),
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          gender: _gender ?? '',
          birthDate: _birthDate != null ? _iso(_birthDate!) : '',
          idType: _idType ?? '',
          idNumber: _idNumberCtrl.text.trim(),
          idExpiryDate: _idExpiryDate != null ? _iso(_idExpiryDate!) : '',
          address: _address ?? '',
          photoSourcePath: _profileImage?.path,
        );
        if (!mounted) return;

        // go to the Create login PIN screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterPinScreen(email: widget.email.trim()),
          ),
        );
      } else {
        _toast(data['message']?.toString() ?? 'Failed to save profile',
            Colors.red);
      }
    } catch (e) {
      if (mounted) _toast('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAvatar(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: _buildForm(),
                    ),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: navy,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'ចុះឈ្មោះប្រើប្រាស់អេស៊ីលីដាម៉ូបាល',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Image.asset(
              'assets/Acleda.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.eco, color: gold, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    const double size = 120;
    return SizedBox(
      height: 130,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Navy band behind the top half of the photo
          Container(height: 70, width: double.infinity, color: navy),
          Positioned(
            top: 10,
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      border: Border.all(color: navy, width: 3),
                    ),
                    child: ClipOval(
                      child: _profileImage != null
                          ? Image.file(
                              _profileImage!,
                              fit: BoxFit.cover,
                              width: size,
                              height: size,
                            )
                          : const Icon(Icons.person,
                              size: 70, color: Colors.white),
                    ),
                  ),
                  // Small camera badge
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First name / Last name
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _labeled(
                Icons.person_outline,
                'នាមខ្លួន',
                _textField(_firstNameCtrl, textCaps: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _labeled(
                Icons.person_outline,
                'នាមត្រកូល',
                _textField(_lastNameCtrl, textCaps: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Gender / Date of birth
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _labeled(
                Icons.people_outline,
                'ភេទ',
                _dropdown(
                  hint: '',
                  value: _gender,
                  items: _genders,
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _labeled(
                Icons.calendar_month_outlined,
                'ថ្ងៃខែឆ្នាំកំណើត',
                _dateField(
                  value: _birthDate,
                  onTap: () => _pickDate(
                    current: _birthDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    onPicked: (d) => setState(() => _birthDate = d),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // ID type
        _dropdown(
          hint: 'ជ្រើសរើសអត្តសញ្ញាណប័ណ្ណ',
          value: _idType,
          items: _idTypes,
          onChanged: (v) => setState(() => _idType = v),
        ),
        const SizedBox(height: 16),

        // ID number
        _textField(_idNumberCtrl, hint: 'លេខអត្តសញ្ញាណប័ណ្ណ'),
        const SizedBox(height: 16),

        // ID expiry date
        _dateField(
          value: _idExpiryDate,
          hint: 'ថ្ងៃផុតកំណត់អត្តសញ្ញាណប័ណ្ណ',
          showArrow: true,
          onTap: () => _pickDate(
            current: _idExpiryDate,
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
            onPicked: (d) => setState(() => _idExpiryDate = d),
          ),
        ),
        const SizedBox(height: 16),

        // Address
        _dropdown(
          hint: 'អាសយដ្ឋាន',
          value: _address,
          items: _addresses,
          onChanged: (v) => setState(() => _address = v),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: navy,
        child: InkWell(
          onTap: _loading ? null : _submit,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: gold,
                        ),
                      )
                    : const Text(
                        'យល់ព្រម',
                        style: TextStyle(
                          color: gold,
                          fontSize: 16,
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

  // ---------- Reusable widgets ----------
  Widget _labeled(IconData icon, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: hintGrey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: hintGrey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _decoration({String? hint}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(3),
          borderSide: BorderSide(color: c, width: 1),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: hintGrey, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: border(borderGrey),
      focusedBorder: border(navy),
      border: border(borderGrey),
    );
  }

  Widget _textField(
    TextEditingController ctrl, {
    String? hint,
    bool textCaps = false,
  }) {
    return TextField(
      controller: ctrl,
      textCapitalization:
          textCaps ? TextCapitalization.characters : TextCapitalization.none,
      style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
      decoration: _decoration(hint: hint),
    );
  }

  Widget _dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: hintGrey),
      decoration: _decoration(hint: hint),
      style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _dateField({
    required DateTime? value,
    required VoidCallback onTap,
    String? hint,
    bool showArrow = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderGrey),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? _fmt(value) : (hint ?? ''),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? const Color(0xFF2C3E50) : hintGrey,
                ),
              ),
            ),
            if (showArrow)
              const Icon(Icons.keyboard_arrow_down, color: hintGrey),
          ],
        ),
      ),
    );
  }
}