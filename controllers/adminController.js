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