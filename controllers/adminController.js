const { pool } = require('../config/db'); // Added pool import for direct queries
const User = require('../models/User');
const AuditLog = require('../models/AuditLog');

exports.getUsers = async (req, res) => {
  try {
    const users = await User.find();
    return res.json({ success: true, users });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.toggleUserStatus = async (req, res) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const newStatus = user.status === 'Active' ? 'Frozen' : 'Active';
    await User.save({ id: user.id, balance: user.balance, status: newStatus });

    return res.json({ success: true, user: { ...user, status: newStatus } });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.getLogs = async (req, res) => {
  try {
    const logs = await AuditLog.find();
    return res.json({ success: true, logs });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ==========================================
// ADMIN: OTP LOGS FUNCTION (Using direct DB Pool)
// ==========================================
exports.getOtpLogs = async (req, res) => {
  try {
    const [otpLogs] = await pool.execute(
      'SELECT * FROM otp_logs ORDER BY created_at DESC LIMIT 200'
    );

    // Render the EJS template and pass the fetched OTP logs data
    return res.render('admin/otp-logs', {
      pageTitle: 'OTP Logs',
      path: '/admin/otp-logs',
      otpLogs
    });
  } catch (err) {
    console.error('❌ OtpLog fetch error:', err.message);
    return res.status(500).send('Database Error: ' + err.message);
  }
};

// ==========================================
// REGISTER PROFILE (called from Flutter app)
// POST /api/v1/profile/register  (multipart/form-data, photo field = "photo")
// ==========================================
const clean = (v) => (v === undefined || v === '' ? null : v);

exports.registerProfile = async (req, res) => {
  try {
    const {
      email, firstName, lastName, gender, birthDate,
      idType, idNumber, idExpiryDate, address,
    } = req.body;

    if (!email || !firstName || !lastName || !idType || !idNumber) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    const photoPath = req.file ? `/uploads/profiles/${req.file.filename}` : null;
    console.log('📷 Photo received:', req.file ? req.file.filename : 'NO FILE RECEIVED');

    await pool.execute(
      `INSERT INTO user_profiles
         (email, first_name, last_name, gender, birth_date, id_type, id_number, id_expiry_date, address, photo_path)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         first_name = VALUES(first_name),
         last_name = VALUES(last_name),
         gender = VALUES(gender),
         birth_date = VALUES(birth_date),
         id_type = VALUES(id_type),
         id_number = VALUES(id_number),
         id_expiry_date = VALUES(id_expiry_date),
         address = VALUES(address),
         photo_path = COALESCE(VALUES(photo_path), photo_path)`,
      [
        email, firstName, lastName, clean(gender), clean(birthDate),
        idType, idNumber, clean(idExpiryDate), clean(address), photoPath,
      ]
    );

    console.log(`✅ Profile saved for ${email}`);
    return res.json({ success: true, message: 'Profile saved', photoPath });
  } catch (err) {
    console.error('❌ registerProfile error:', err.message);
    return res.status(500).json({ success: false, message: err.message });
  }
};