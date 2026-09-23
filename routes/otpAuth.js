const express = require("express");
const router = express.Router();
const nodemailer = require("nodemailer");
const { pool } = require("../config/db");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

router.post("/send-otp", async (req, res) => {
  const { email } = req.body;
  if (!email || !email.includes("@")) {
    return res.status(400).json({ success: false, message: "Invalid email" });
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

  try {
    // Clean up old rows older than 7 days
    await pool.execute(
      `DELETE FROM otp_codes WHERE created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)`
    );

    await pool.execute(
      `UPDATE otp_codes SET status = 'EXPIRED' WHERE email = ? AND status = 'PENDING'`,
      [email]
    );

    const [result] = await pool.execute(
      `INSERT INTO otp_codes (email, otp_code, status, expires_at) VALUES (?, ?, 'PENDING', ?)`,
      [email, otp, expiresAt]
    );
    console.log(`✅ Saved OTP to DB (row id ${result.insertId}) for ${email}: ${otp}`);

    await transporter.sendMail({
      from: `"Bank App" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: "Your verification code",
      text: `Your OTP code is ${otp}. It expires in 5 minutes.`,
    });

    res.json({ success: true });
  } catch (err) {
    console.error("❌ Send OTP error:", err.message);
    res.status(500).json({ success: false, message: "Failed to send OTP" });
  }
});

router.post("/verify-otp", async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ success: false, message: "Email and OTP are required" });
  }

  try {
    const [rows] = await pool.execute(
      `SELECT * FROM otp_codes WHERE email = ? AND status = 'PENDING' ORDER BY created_at DESC LIMIT 1`,
      [email]
    );
    const record = rows[0];

    if (!record) {
      return res.status(400).json({ success: false, message: "No OTP requested for this email" });
    }
    if (new Date() > new Date(record.expires_at)) {
      await pool.execute(`UPDATE otp_codes SET status = 'EXPIRED' WHERE id = ?`, [record.id]);
      return res.status(400).json({ success: false, message: "OTP expired, please request a new one" });
    }
    if (record.otp_code !== otp) {
      return res.status(400).json({ success: false, message: "Incorrect code" });
    }

    await pool.execute(
      `UPDATE otp_codes SET status = 'VERIFIED', verified_at = NOW(), otp_code = '******' WHERE id = ?`,
      [record.id]
    );
    console.log(`✅ Verified OTP row ${record.id} for ${email}`);

    res.json({ success: true });
  } catch (err) {
    console.error("❌ Verify OTP error:", err.message);
    res.status(500).json({ success: false, message: "Verification failed" });
  }
});

module.exports = router;