const nodemailer = require('nodemailer');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Transaction = require('../models/Transaction');

const normalizeEmail = (email) => (
  typeof email === 'string' ? email.trim().toLowerCase() : ''
);

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

// Full login: email + password required, generates first OTP
exports.requestOtp = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const { password } = req.body;

    if (!email || !email.includes('@') || typeof password !== 'string' || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const validPassword = await User.comparePassword(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (user.status.toUpperCase() !== 'ACTIVE') {
      return res.status(403).json({ success: false, message: 'Account is frozen' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await User.setOtp(user.email, otp, expiresAt);

    console.log(`[${new Date().toISOString()}] OTP generated for ${user.email}: ${otp}`);

    res.json({ success: true, message: 'OTP sent to your email' });

    transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: 'Your OTP Code',
      text: `Your OTP is ${otp}. It expires in 5 minutes.`
    }).then(() => {
      console.log(`[${new Date().toISOString()}] OTP email accepted by Gmail for ${user.email}`);
    }).catch(err => {
      console.error(`[${new Date().toISOString()}] Failed to send OTP email to ${user.email}:`, err.message);
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

// ✅ Resend OTP — email only, no password required
exports.resendOtp = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);

    if (!email || !email.includes('@')) {
      return res.status(400).json({ success: false, message: 'Valid email is required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    if (user.status.toUpperCase() !== 'ACTIVE') {
      return res.status(403).json({ success: false, message: 'Account is frozen' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await User.setOtp(user.email, otp, expiresAt);

    console.log(`[${new Date().toISOString()}] OTP resent for ${user.email}: ${otp}`);

    res.json({ success: true, message: 'OTP resent to your email' });

    transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: 'Your OTP Code',
      text: `Your OTP is ${otp}. It expires in 5 minutes.`
    }).then(() => {
      console.log(`[${new Date().toISOString()}] Resent OTP email accepted by Gmail for ${user.email}`);
    }).catch(err => {
      console.error(`[${new Date().toISOString()}] Failed to resend OTP email to ${user.email}:`, err.message);
    });

  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const { otp } = req.body;

    if (!email || !email.includes('@') || typeof otp !== 'string' || !otp) {
      return res.status(400).json({ success: false, message: 'Email and OTP are required' });
    }

    const user = await User.findOne({ email });
    if (!user || !user.otpCode) {
      return res.status(400).json({ success: false, message: 'No OTP requested' });
    }
    if (user.otpCode !== otp) {
      return res.status(400).json({ success: false, message: 'Incorrect OTP' });
    }
    if (new Date() > new Date(user.otpExpiresAt)) {
      return res.status(400).json({ success: false, message: 'OTP expired' });
    }

    await User.clearOtp(user.email);

    const token = jwt.sign(
      { id: user.user_id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    return res.json({
      success: true,
      message: 'Login successful',
      token,
      user: { id: user.user_id, name: user.full_name, email: user.email, role: user.role }
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.getClientDashboard = async (req, res) => {
  try {
    const account = await User.findById(req.user.id);
    const transactions = await Transaction.find().sort({ date: -1 });
    res.json({ success: true, account, transactions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.payBill = async (req, res) => {
  try {
    res.json({ success: true, message: "Bill payment endpoint processed successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// New: Register — creates a brand-new account
exports.register = async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);
    const { password, name } = req.body;

    if (!email || !email.includes('@') || !password || !name) {
      return res.status(400).json({ success: false, message: 'Name, email and password are required' });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Account already exists' });
    }

    // Simple unique account number generator — replace with your own scheme if needed
    const accountNo = Date.now().toString().slice(-10);

    await User.create({
      name,
      email,
      password, // plain text here — User.create() hashes it internally
      accountNo,
      status: 'ACTIVE',
      role: 'client'
    });

    res.json({ success: true, message: 'Account created successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};