require('dotenv').config();
const express = require('express');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
const multer = require('multer');

// Import MySQL Pool Connection and connectDB function
const { connectDB, pool } = require('./config/db');
const apiRoutes = require('./routes/apiRoutes');
const otpAuthRoutes = require('./routes/otpAuth');
const adminController = require('./controllers/adminController');

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
  adminController.registerProfile
);

// ==========================================
// 📱 FLUTTER API: SET LOGIN PIN
// ==========================================
app.post('/api/v1/register/set-pin', async (req, res) => {
  const { email, pin } = req.body;

  if (!email || !pin) {
    return res.status(400).json({ success: false, message: 'Email and PIN are required' });
  }

  try {
    // You can optionally save or update the PIN in your database here:
    // await pool.execute('UPDATE user_profiles SET pin = ? WHERE email = ?', [pin, email]);

    return res.status(200).json({
      success: true,
      message: 'PIN set successfully',
      accountNumber: '1000804344',
      email: email
    });
  } catch (err) {
    console.error("Set PIN Error:", err.message);
    return res.status(500).json({ success: false, message: 'Server error: ' + err.message });
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
      'SELECT * FROM user_profiles ORDER BY id DESC'
    );
    res.render('admin/registered', { pageTitle: 'Users Registered', profiles });
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
  console.log(`👉 OTP Logs:        http://localhost:${PORT}/admin/otp-logs`);
  console.log(`👉 Registered:      http://localhost:${PORT}/admin/registered`);

  await connectDB();
});