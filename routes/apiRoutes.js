const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const nodemailer = require("nodemailer");
const { pool } = require("../config/db");

const otpLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // max 5 requests per minute per IP
  message: { success: false, message: 'Too many OTP requests. Please wait a moment.' }
});

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

const clientController = require('../controllers/clientController');
const adminController = require('../controllers/adminController');
const transactionController = require('../controllers/transactionController');
const requireAuth = require('../middleware/auth');

// ==========================================
// OTP AUTH ROUTES (Handles Database Saving & Email)
// ==========================================

const handleOtpRequest = async (req, res) => {
  const { email } = req.body;
  if (!email || !email.includes("@")) {
    return res.status(400).json({ success: false, message: "Invalid email" });
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  try {
    // 1. Mark previous active/sent codes as expired for this email
    await pool.execute(
      `UPDATE otp_logs SET status = 'expired' WHERE email = ? AND status = 'sent'`,
      [email]
    );

    // 2. Insert new OTP into 'otp_logs' matching your table columns
    const [result] = await pool.execute(
      `INSERT INTO otp_logs (email, otp_code, status) VALUES (?, ?, 'sent')`,
      [email, otp]
    );
    console.log(`✅ Saved OTP to DB (row id ${result.insertId}) for ${email}: ${otp}`);

    // 3. Send email via Nodemailer
    await transporter.sendMail({
      from: `"Bank App" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: "Your verification code",
      text: `Your OTP code is ${otp}. It expires in 5 minutes.`,
    });

    res.json({ success: true, message: "OTP sent successfully" });
  } catch (err) {
    console.error("❌ Send OTP error:", err.message);
    res.status(500).json({ success: false, message: "Failed to send OTP" });
  }
};

router.post('/auth/request-otp', otpLimiter, handleOtpRequest);
router.post('/auth/resend-otp', otpLimiter, handleOtpRequest);

router.post('/auth/verify-otp', async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ success: false, message: "Email and OTP are required" });
  }

  try {
    const [rows] = await pool.execute(
      `SELECT * FROM otp_logs WHERE email = ? AND status = 'sent' ORDER BY created_at DESC LIMIT 1`,
      [email]
    );
    const record = rows[0];

    if (!record) {
      return res.status(400).json({ success: false, message: "No active OTP found for this email" });
    }
    if (record.otp_code !== otp) {
      return res.status(400).json({ success: false, message: "Incorrect code" });
    }

    // Mark code as verified
    await pool.execute(
      `UPDATE otp_logs SET status = 'verified', verified_at = NOW(), otp_code = '******' WHERE id = ?`,
      [record.id]
    );
    console.log(`✅ Verified OTP row ${record.id} for ${email}`);

    res.json({ success: true });
  } catch (err) {
    console.error("❌ Verify OTP error:", err.message);
    res.status(500).json({ success: false, message: "Verification failed" });
  }
});

// ==========================================
// CLIENT API ROUTES
// ==========================================
router.get('/client/dashboard', requireAuth, clientController.getClientDashboard);
router.post('/client/transfer', requireAuth, transactionController.transferMoney);
router.post('/client/pay-bill', requireAuth, clientController.payBill);

// ==========================================
// ADMIN API ROUTES
// ==========================================
router.get('/admin/users', requireAuth, adminController.getUsers);
router.post('/admin/users/toggle-status', requireAuth, adminController.toggleUserStatus);
router.get('/admin/logs', requireAuth, adminController.getLogs);

module.exports = router;