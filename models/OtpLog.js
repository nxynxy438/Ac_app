const { pool } = require('../config/db');

const OtpLog = {
  create: async (email, otpCode) => {
    try {
      const [result] = await pool.execute(
        'INSERT INTO otp_logs (email, otp_code, status) VALUES (?, ?, ?)',
        [email, otpCode, 'sent']
      );
      console.log(`✅ OTP logged to DB for ${email}: ${otpCode}`);
      return result.insertId;
    } catch (err) {
      console.error('❌ OtpLog.create failed:', err.message);
      throw err;
    }
  },

  markVerified: async (email, otpCode) => {
    try {
      await pool.execute(
        "UPDATE otp_logs SET status = 'verified', verified_at = NOW() WHERE email = ? AND otp_code = ? ORDER BY id DESC LIMIT 1",
        [email, otpCode]
      );
      console.log(`✅ OTP marked verified for ${email}`);
    } catch (err) {
      console.error('❌ OtpLog.markVerified failed:', err.message);
      throw err;
    }
  },

  getAll: async () => {
    try {
      const [rows] = await pool.execute(
        'SELECT * FROM otp_logs ORDER BY created_at DESC'
      );
      return rows;
    } catch (err) {
      console.error('❌ OtpLog.getAll failed:', err.message);
      throw err;
    }
  }
};

module.exports = OtpLog;