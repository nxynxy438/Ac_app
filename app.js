require('dotenv').config();
const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const multer = require('multer');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');

// Import MySQL Pool Connection and connectDB function
const { connectDB, pool } = require('./config/db');
const apiRoutes = require('./routes/apiRoutes');
const otpAuthRoutes = require('./routes/otpAuth');

const app = express();

// ==========================================
// MIDDLEWARES & CONFIGURATION
// ==========================================
app.use(cors({ 
  origin: '*', 
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'], 
  allowedHeaders: ['Content-Type', 'Authorization'] 
}));

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

// View Engine & Static Assets Setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use(express.static(path.join(__dirname, 'public')));

// ==========================================
// FILE UPLOAD SETUP (profile photos)
// Saved in: <project>/uploads/profiles  ->  served at /uploads/profiles/<file>
// ==========================================
const profileUploadDir = path.join(__dirname, 'uploads', 'profiles');
fs.mkdirSync(profileUploadDir, { recursive: true });

const allowedExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'];

const profileUpload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, profileUploadDir),
    filename: (req, file, cb) => {
      let ext = path.extname(file.originalname).toLowerCase();
      if (!ext) ext = '.jpg'; // fallback so the browser can show it
      cb(null, Date.now() + '-' + Math.round(Math.random() * 1e6) + ext);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    console.log('📎 Upload:', file.originalname, '|', file.mimetype);
    const ok =
      file.mimetype.startsWith('image/') ||
      file.mimetype === 'application/octet-stream' ||
      allowedExt.includes(ext);
    ok ? cb(null, true) : cb(new Error('Only image files are allowed'));
  },
});

// ==========================================
// API ENDPOINTS MOUNTING
// ==========================================
app.use('/api/v1', apiRoutes);
app.use('/api/v1/auth', otpAuthRoutes);

// ==========================================
// 📱 FLUTTER API: REGISTER PROFILE (with photo)
// Field name for the image must be "photo"
// Saves ALL profile fields + photo into table: user_profiles
// ==========================================
app.post(
  '/api/v1/profile/register',
  (req, res, next) => {
    profileUpload.single('photo')(req, res, (err) => {
      if (err) {
        return res.status(400).json({ success: false, message: err.message });
      }
      next();
    });
  },
  async (req, res) => {
    try {
      console.log('📥 Profile request received:', req.body);
      const {
        email, firstName, lastName, gender, birthDate,
        idType, idNumber, idExpiryDate, address,
      } = req.body;

      if (!email || !firstName || !lastName || !idNumber) {
        return res.status(400).json({ success: false, message: 'Missing required fields' });
      }

      const photoPath = req.file ? `/uploads/profiles/${req.file.filename}` : null;
      if (req.file) console.log('📷 Photo received:', req.file.filename);

      const values = [
        firstName,
        lastName,
        gender || null,
        birthDate || null,
        idType || null,
        idNumber,
        idExpiryDate || null,
        address || null,
      ];

      // Same email submitting again -> update the row instead of duplicating it
      const [existing] = await pool.execute(
        'SELECT id FROM user_profiles WHERE email = ? LIMIT 1',
        [email]
      );

      if (existing.length > 0) {
        await pool.execute(
          `UPDATE user_profiles SET
             first_name = ?, last_name = ?, gender = ?, birth_date = ?,
             id_type = ?, id_number = ?, id_expiry_date = ?, address = ?,
             photo_path = COALESCE(?, photo_path),
             created_at = NOW()
           WHERE id = ?`,
          [...values, photoPath, existing[0].id]
        );
      } else {
        await pool.execute(
          `INSERT INTO user_profiles
             (email, first_name, last_name, gender, birth_date,
              id_type, id_number, id_expiry_date, address, photo_path)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [email, ...values, photoPath]
        );
      }

      console.log('✅ Profile saved for', email);
      res.json({ success: true, message: 'Registration saved' });
    } catch (e) {
      console.error('❌ Register profile error:', e.message);
      res.status(500).json({ success: false, message: 'Server error: ' + e.message });
    }
  }
);

// ==========================================
// 📱 FLUTTER API: SET LOGIN PIN
// Saves the PIN (hashed, never plain text) on the user's profile row
// ==========================================
const DEFAULT_ACCOUNT_NUMBER = '1000804344'; // placeholder, same value as before

app.post('/api/v1/register/set-pin', async (req, res) => {
  const { email, pin } = req.body;

  if (!email || !pin) {
    return res.status(400).json({ success: false, message: 'Email and PIN are required' });
  }
  if (!/^\d{4,6}$/.test(String(pin))) {
    return res.status(400).json({ success: false, message: 'PIN must be 4 to 6 digits' });
  }

  try {
    const pinHash = await bcrypt.hash(String(pin), 10);
    const [result] = await pool.execute(
      'UPDATE user_profiles SET pin_hash = ? WHERE email = ?',
      [pinHash, email]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({
        success: false,
        message: 'Profile not found. Please fill in your profile first.',
      });
    }

    console.log('🔐 PIN saved for', email);
    return res.status(200).json({
      success: true,
      message: 'PIN set successfully',
      accountNumber: DEFAULT_ACCOUNT_NUMBER,
      email: email
    });
  } catch (err) {
    console.error("Set PIN Error:", err.message);
    return res.status(500).json({ success: false, message: 'Server error: ' + err.message });
  }
});

// ==========================================
// 📱 FLUTTER API: LOGIN  (email + PIN created at registration)
// POST /api/v1/auth/login   body: { email, pin }
// ==========================================
const loginLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10, // 10 attempts per minute per IP
  message: { success: false, message: 'Too many login attempts. Please wait a minute.' },
});

app.post('/api/v1/auth/login', loginLimiter, async (req, res) => {
  const { email, pin } = req.body;

  if (!email || !pin) {
    return res.status(400).json({ success: false, message: 'Email and PIN are required' });
  }

  try {
    const [rows] = await pool.execute(
      'SELECT * FROM user_profiles WHERE email = ? LIMIT 1',
      [email]
    );
    const user = rows[0];

    // Same message for "no such user" and "wrong PIN" so nobody can probe emails
    if (!user || !user.pin_hash) {
      return res.status(401).json({ success: false, message: 'Incorrect email or PIN' });
    }

    const ok = await bcrypt.compare(String(pin), user.pin_hash);
    if (!ok) {
      console.log('⚠️ Failed login for', email);
      return res.status(401).json({ success: false, message: 'Incorrect email or PIN' });
    }

    console.log('✅ Login success for', email);
    return res.json({
      success: true,
      message: 'Login successful',
      accountNumber: DEFAULT_ACCOUNT_NUMBER,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        gender: user.gender,
        birthDate: user.birth_date,
        idType: user.id_type,
        idNumber: user.id_number,
        idExpiryDate: user.id_expiry_date,
        address: user.address,
        photoPath: user.photo_path,
      },
    });
  } catch (err) {
    console.error('Login Error:', err.message);
    return res.status(500).json({ success: false, message: 'Server error: ' + err.message });
  }
});

// ==========================================
// 📱 FLUTTER API: SAVE A TRANSACTION (own transfer / phone top-up)
// POST /api/v1/transactions   (JSON)
// Safe to send twice: the same txnRef is only stored once.
// ==========================================
app.post('/api/v1/transactions', async (req, res) => {
  try {
    const {
      txnRef, email, type, fromAccount, fromName, toAccount, toName,
      amount, currency, purpose, status, scheduledFor,
    } = req.body;

    const amt = Number(amount);
    if (
      !txnRef || !fromAccount ||
      !['own_transfer', 'top_up'].includes(type) ||
      !['KHR', 'USD'].includes(currency) ||
      !Number.isFinite(amt) || amt <= 0
    ) {
      return res.status(400).json({ success: false, message: 'Missing or invalid fields' });
    }

    await pool.execute(
      `INSERT INTO transaction_history
         (txn_ref, user_email, type, from_account, from_name, to_account, to_name,
          amount, currency, purpose, status, scheduled_for)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE txn_ref = txn_ref`,
      [
        txnRef,
        email || null,
        type,
        fromAccount,
        fromName || null,
        toAccount || null,
        toName || null,
        amt,
        currency,
        purpose || null,
        status === 'scheduled' ? 'scheduled' : 'completed',
        scheduledFor || null,
      ]
    );

    console.log(`🧾 Transaction saved: ${txnRef} (${type}) ${amt} ${currency}`);
    res.json({ success: true });
  } catch (err) {
    console.error('❌ Save transaction error:', err.message);
    res.status(500).json({ success: false, message: 'Server error: ' + err.message });
  }
});

// ==========================================
// 📱 FLUTTER API: TRANSFER ENDPOINT
// ==========================================
app.post('/api/v1/transfer', async (req, res) => {
  const { recipientAccount, amount } = req.body;
  const transferAmt = parseFloat(amount);

  if (isNaN(transferAmt) || transferAmt <= 0) {
    return res.status(400).json({ success: false, message: 'Invalid transfer amount' });
  }

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [userRows] = await connection.execute('SELECT * FROM accounts LIMIT 1 FOR UPDATE');
    let account = userRows[0];

    if (!account || transferAmt > account.balance) {
      await connection.rollback();
      connection.release();
      return res.status(400).json({ success: false, message: 'Insufficient balance or account not found' });
    }

    const newBalance = account.balance - transferAmt;

    await connection.execute('UPDATE accounts SET balance = ? WHERE account_id = ?', [newBalance, account.account_id]);

    const txnRef = `TXN-${Math.floor(1000 + Math.random() * 9000)}`;
    await connection.execute(
      `INSERT INTO transactions (transaction_ref, sender_account_id, amount, type, status) VALUES (?, ?, ?, ?, ?)`,
      [txnRef, account.account_id, transferAmt, 'LOCAL_TRANSFER', 'COMPLETED']
    );

    await connection.commit();
    connection.release();

    res.status(200).json({ success: true, message: 'Transfer successful and saved to database!' });
  } catch (err) {
    await connection.rollback();
    connection.release();
    console.error("API Transfer Error:", err.message);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==========================================
// 🧪 TEMPORARY SEED ROUTE
// ==========================================
app.get('/seed-user', async (req, res) => {
  try {
    const [existingRows] = await pool.execute('SELECT * FROM accounts WHERE user_id = ? LIMIT 1', [1]);
    let existing = existingRows[0];

    if (existing) {
      return res.send(`Client account already exists: ${existing.account_number} (Balance: $${existing.balance})`);
    }

    const [result] = await pool.execute(
      `INSERT INTO accounts (account_number, account_type, balance, currency, status, user_id) VALUES (?, ?, ?, ?, ?, ?)`,
      ["ACC-8801", "Savings", 5200.00, "USD", "Active", 1]
    );

    res.send(`Successfully created test account with ID: ${result.insertId}`);
  } catch (err) {
    res.status(500).send("Error seeding account: " + err.message);
  }
});

// ==========================================
// CLIENT WEB PORTAL (EJS)
// ==========================================
app.get('/', (req, res) => res.redirect('/client'));

app.get('/client', async (req, res) => {
  try {
    const [userRows] = await pool.execute('SELECT * FROM accounts LIMIT 1');
    const account = userRows[0] || {
      account_number: "ACC-8801",
      balance: 5200.00,
      currency: "USD",
      status: "Active"
    };

    account.accountNo = account.account_number;

    const [transactions] = await pool.execute('SELECT * FROM transactions ORDER BY created_at DESC');

    res.render('client/dashboard', {
      pageTitle: 'Customer Dashboard',
      account,
      transactions
    });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

app.get('/client/transfer', async (req, res) => {
  try {
    const [userRows] = await pool.execute('SELECT * FROM accounts LIMIT 1');
    const account = userRows[0] || { balance: 5200.00, account_number: "ACC-8801" };
    account.accountNo = account.account_number;
    res.render('client/transfer', { pageTitle: 'Fund Transfer', account, message: null });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

app.post('/client/transfer', async (req, res) => {
  const { recipientAccount, amount } = req.body;
  const transferAmt = parseFloat(amount);

  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const [userRows] = await connection.execute('SELECT * FROM accounts LIMIT 1 FOR UPDATE');
    let account = userRows[0];
    if (account) account.accountNo = account.account_number;

    if (!account || transferAmt > account.balance) {
      await connection.rollback();
      connection.release();
      return res.render('client/transfer', {
        pageTitle: 'Fund Transfer',
        account: account || { balance: 0, accountNo: 'ACC-8801' },
        message: { type: 'danger', text: 'Insufficient balance or user account not found!' }
      });
    }

    const newBalance = account.balance - transferAmt;

    await connection.execute('UPDATE accounts SET balance = ? WHERE account_id = ?', [newBalance, account.account_id]);
    account.balance = newBalance;

    const txnRef = `TXN-${Math.floor(1000 + Math.random() * 9000)}`;
    await connection.execute(
      `INSERT INTO transactions (transaction_ref, sender_account_id, amount, type, status) VALUES (?, ?, ?, ?, ?)`,
      [txnRef, account.account_id, transferAmt, 'LOCAL_TRANSFER', 'COMPLETED']
    );

    await connection.commit();
    connection.release();

    res.render('client/transfer', {
      pageTitle: 'Fund Transfer',
      account,
      message: { type: 'success', text: `Successfully transferred $${transferAmt.toFixed(2)} to ${recipientAccount}` }
    });
  } catch (err) {
    await connection.rollback();
    connection.release();
    res.status(500).send("Transfer Failed: " + err.message);
  }
});

app.get('/client/pay-bills', async (req, res) => {
  try {
    const [userRows] = await pool.execute('SELECT * FROM accounts LIMIT 1');
    const account = userRows[0] || { balance: 5200.00, account_number: "ACC-8801" };
    account.accountNo = account.account_number;
    res.render('client/pay-bills', { pageTitle: 'Pay Utility Bills', account, message: null });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

// ==========================================
// ADMIN WEB PORTAL (EJS)
// ==========================================
app.get('/admin', async (req, res) => {
  try {
    const [usersList] = await pool.execute('SELECT * FROM accounts');

    const formattedUsers = usersList.map(u => ({
      ...u,
      balance: parseFloat(u.balance) || 0
    }));

    res.render('admin/dashboard', {
      pageTitle: 'Admin Dashboard',
      stats: {
        totalUsers: formattedUsers.length,
        activeUsers: formattedUsers.filter(u => (u.status || '').trim().toLowerCase() === 'active').length,
        frozenUsers: formattedUsers.filter(u => (u.status || '').trim().toLowerCase() === 'frozen').length,
        totalVolume: "$00"
      }
    });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

app.get('/admin/users', async (req, res) => {
  try {
    const [usersList] = await pool.execute('SELECT * FROM accounts');

    const users = usersList.map(user => ({
      ...user,
      id: user.account_id,
      accountNo: user.account_number,
      name: user.username || "Client User",
      balance: parseFloat(user.balance) || 0
    }));

    res.render('admin/users', { pageTitle: 'User & Account Management', users });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

app.post('/admin/users/toggle-status', async (req, res) => {
  try {
    const { userId } = req.body;
    const [userRows] = await pool.execute('SELECT * FROM accounts WHERE account_id = ?', [userId]);
    const user = userRows[0];

    if (user) {
      const currentStatus = (user.status || '').trim().toLowerCase();
      const newStatus = currentStatus === 'active' ? 'Frozen' : 'Active';

      await pool.execute('UPDATE accounts SET status = ? WHERE account_id = ?', [newStatus, userId]);

      await pool.execute(
        `INSERT INTO audit_logs (action, user_id) VALUES (?, ?)`,
        [`Account Status changed to ${newStatus} for ${user.account_number}`, user.user_id || 1]
      );
    }
    res.redirect('/admin/users');
  } catch (err) {
    res.status(500).send("Error updating status: " + err.message);
  }
});

app.get('/admin/logs', async (req, res) => {
  try {
    const [logs] = await pool.execute('SELECT * FROM audit_logs ORDER BY created_at DESC');
    res.render('admin/logs', { pageTitle: 'Activity Logs & Audits', logs });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

// ==========================================
// ADMIN: OTP LOGS
// ==========================================
app.get('/admin/otp-logs', async (req, res) => {
  try {
    const [otpLogs] = await pool.execute(
      'SELECT * FROM otp_logs ORDER BY created_at DESC LIMIT 200'
    );
    res.render('admin/otp-logs', { pageTitle: 'OTP Logs', otpLogs });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

// ==========================================
// ADMIN: USERS REGISTERED (from Flutter app)
// ==========================================
app.get('/admin/registered', async (req, res) => {
  try {
    const [profiles] = await pool.execute(
      'SELECT * FROM user_profiles ORDER BY created_at DESC, id DESC'
    );
    res.render('admin/registered', { pageTitle: 'Users Registered', profiles });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

// ==========================================
// ADMIN: HISTORY TRANSACTION (from Flutter app)
// ==========================================
app.get('/admin/history-transactions', async (req, res) => {
  try {
    const [transactions] = await pool.execute(
      'SELECT * FROM transaction_history ORDER BY created_at DESC, id DESC LIMIT 500'
    );
    res.render('admin/history-transactions', {
      pageTitle: 'History Transaction',
      transactions,
    });
  } catch (err) {
    res.status(500).send("Database Error: " + err.message);
  }
});

// ==========================================
// START SERVER
// ==========================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  console.log(`🚀 Server running successfully at http://localhost:${PORT}`);
  console.log(`👉 Customer Portal: http://localhost:${PORT}/client`);
  console.log(`👉 Admin Portal:    http://localhost:${PORT}/admin`);
  console.log(`👉 Seed Database:   http://localhost:${PORT}/seed-user`);
  console.log(`👉 Request OTP:     POST http://localhost:${PORT}/api/v1/auth/request-otp`);
  console.log(`👉 Verify OTP:      POST http://localhost:${PORT}/api/v1/auth/verify-otp`);
  console.log(`👉 Register Profile: POST http://localhost:${PORT}/api/v1/profile/register`);
  console.log(`👉 Set PIN:         POST http://localhost:${PORT}/api/v1/register/set-pin`);
  console.log(`👉 Login:           POST http://localhost:${PORT}/api/v1/auth/login`);
  console.log(`👉 OTP Logs:        http://localhost:${PORT}/admin/otp-logs`);
  console.log(`👉 Registered:      http://localhost:${PORT}/admin/registered`);
  console.log(`👉 History Txn:     http://localhost:${PORT}/admin/history-transactions`);
  console.log(`👉 Save Txn:        POST http://localhost:${PORT}/api/v1/transactions`);

  await connectDB();

  // Add the pin_hash column automatically if it does not exist yet
  try {
    await pool.execute('ALTER TABLE user_profiles ADD COLUMN pin_hash VARCHAR(100) NULL');
    console.log('🛠️  Added column user_profiles.pin_hash');
  } catch (e) {
    if (e.code !== 'ER_DUP_FIELDNAME') console.error('pin_hash migration:', e.message);
  }

  // Create the transaction_history table automatically if it does not exist
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS transaction_history (
        id INT AUTO_INCREMENT PRIMARY KEY,
        txn_ref VARCHAR(64) NOT NULL UNIQUE,
        user_email VARCHAR(255) NULL,
        type VARCHAR(20) NOT NULL,
        from_account VARCHAR(50) NOT NULL,
        from_name VARCHAR(150) NULL,
        to_account VARCHAR(80) NULL,
        to_name VARCHAR(150) NULL,
        amount DECIMAL(18,2) NOT NULL,
        currency VARCHAR(3) NOT NULL,
        purpose VARCHAR(255) NULL,
        status VARCHAR(20) NOT NULL DEFAULT 'completed',
        scheduled_for DATE NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) CHARACTER SET utf8mb4
    `);
    console.log('🛠️  transaction_history table ready');
  } catch (e) {
    console.error('transaction_history table:', e.message);
  }
});