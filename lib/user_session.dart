import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps everything the user entered during registration, saves it on the
/// device, and can re-load the real profile from your Node server.
///
///  - Profile data -> shared_preferences (survives closing the app)
///  - Login PIN (salted SHA-256 hash, never the plain PIN) -> flutter_secure_storage
///  - Real profile from the database -> syncFromServer()
///
/// Use anywhere:  UserSession.instance.firstName
class UserSession extends ChangeNotifier {
  UserSession._();
  static final UserSession instance = UserSession._();

  /// Same address you use for request-otp / profile register.
  ///   Android emulator : http://10.0.2.2:3000
  ///   Real phone       : http://<your PC IP>:3000
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const _secure = FlutterSecureStorage();

  // Profile fields
  String email = '';
  String firstName = '';
  String lastName = '';
  String gender = '';
  String birthDate = ''; // yyyy-MM-dd
  String idType = '';
  String idNumber = '';
  String idExpiryDate = ''; // yyyy-MM-dd
  String address = '';
  String photoPath = ''; // local copy inside the app folder
  String photoUrl = ''; // full URL of the photo stored on the server

  bool pinSet = false;

  String get fullName => '$firstName $lastName'.trim();
  bool get isRegistered => email.isNotEmpty && pinSet;

  // ---------- Load (call once in main() before runApp) ----------
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    email = p.getString('email') ?? '';
    firstName = p.getString('firstName') ?? '';
    lastName = p.getString('lastName') ?? '';
    gender = p.getString('gender') ?? '';
    birthDate = p.getString('birthDate') ?? '';
    idType = p.getString('idType') ?? '';
    idNumber = p.getString('idNumber') ?? '';
    idExpiryDate = p.getString('idExpiryDate') ?? '';
    address = p.getString('address') ?? '';
    photoPath = p.getString('photoPath') ?? '';
    photoUrl = p.getString('photoUrl') ?? '';

    final hash = await _secure.read(key: 'pin_hash');
    pinSet = hash != null && hash.isNotEmpty;
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('email', email);
    await p.setString('firstName', firstName);
    await p.setString('lastName', lastName);
    await p.setString('gender', gender);
    await p.setString('birthDate', birthDate);
    await p.setString('idType', idType);
    await p.setString('idNumber', idNumber);
    await p.setString('idExpiryDate', idExpiryDate);
    await p.setString('address', address);
    await p.setString('photoPath', photoPath);
    await p.setString('photoUrl', photoUrl);
    notifyListeners();
  }

  /// Call this on the OTP screen right after the OTP is verified, so the app
  /// knows WHO is logging in (then syncFromServer() can load their profile).
  Future<void> setEmail(String value) async {
    email = value.trim();
    await _persist();
  }

  // ---------- Save profile (called after the profile form is saved) ----------
  Future<void> saveProfile({
    required String email,
    required String firstName,
    required String lastName,
    String gender = '',
    String birthDate = '',
    String idType = '',
    String idNumber = '',
    String idExpiryDate = '',
    String address = '',
    String? photoSourcePath,
  }) async {
    this.email = email;
    this.firstName = firstName;
    this.lastName = lastName;
    this.gender = gender;
    this.birthDate = birthDate;
    this.idType = idType;
    this.idNumber = idNumber;
    this.idExpiryDate = idExpiryDate;
    this.address = address;

    if (photoSourcePath != null && photoSourcePath.isNotEmpty) {
      try {
        photoPath = await _copyPhoto(photoSourcePath);
      } catch (e) {
        debugPrint('Could not copy photo: $e');
      }
    }
    await _persist();
  }

  // The picker's file lives in a cache folder that Android can delete,
  // so keep our own copy in the app's documents folder.
  Future<String> _copyPhoto(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = '${dir.path}/profile_photo.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  // ---------- Load the REAL profile from your Node server ----------
  /// Needs the route in server_profile_route.js on your backend.
  /// Returns true when the profile was found and saved.
  Future<bool> syncFromServer() async {
    if (email.isEmpty) return false;
    try {
      final uri = Uri.parse('$baseUrl/api/v1/profile/by-email')
          .replace(queryParameters: {'email': email});
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return false;

      final body = jsonDecode(res.body);
      if (body is! Map || body['success'] != true) return false;
      final d = body['data'];
      if (d is! Map) return false;

      firstName = _pick(d, ['firstName', 'first_name'], firstName);
      lastName = _pick(d, ['lastName', 'last_name'], lastName);
      gender = _pick(d, ['gender'], gender);
      birthDate = _date(_pick(d, ['birthDate', 'birth_date'], birthDate));
      idType = _pick(d, ['idType', 'id_type'], idType);
      idNumber = _pick(d, ['idNumber', 'id_number'], idNumber);
      idExpiryDate =
          _date(_pick(d, ['idExpiryDate', 'id_expiry_date'], idExpiryDate));
      address = _pick(d, ['address'], address);

      final photo = _pick(d, ['photoUrl', 'photo_url', 'photo'], '');
      if (photo.isNotEmpty) {
        photoUrl = photo.startsWith('http')
            ? photo
            : '$baseUrl${photo.startsWith('/') ? '' : '/'}$photo';
      }

      await _persist();
      return true;
    } catch (e) {
      debugPrint('syncFromServer failed: $e');
      return false; // keep showing what is saved on the phone
    }
  }

  String _pick(Map d, List<String> keys, String fallback) {
    for (final k in keys) {
      final v = d[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  // "1999-05-20T00:00:00.000Z" -> "1999-05-20"
  String _date(String v) => v.length >= 10 ? v.substring(0, 10) : v;

  // ---------- PIN ----------
  Future<void> savePin(String pin) async {
    final rnd = Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => rnd.nextInt(256)));
    await _secure.write(key: 'pin_salt', value: salt);
    await _secure.write(key: 'pin_hash', value: _hash(salt, pin));
    pinSet = true;
    notifyListeners();
  }

  /// Use this on your login screen to check the PIN the user types.
  Future<bool> verifyPin(String pin) async {
    final salt = await _secure.read(key: 'pin_salt');
    final hash = await _secure.read(key: 'pin_hash');
    if (salt == null || hash == null) return false;
    return _hash(salt, pin) == hash;
  }

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  // ---------- Log out / reset ----------
  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await _secure.deleteAll();
    email = firstName = lastName = gender = birthDate = '';
    idType = idNumber = idExpiryDate = address = photoPath = photoUrl = '';
    pinSet = false;
    notifyListeners();
  }
}