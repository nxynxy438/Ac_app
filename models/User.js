const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');

// mysql2 throws on `undefined`, so turn empty values into NULL
const n = (v) => (v === undefined || v === null || v === '' ? null : v);

const User = {
  async create(userData) {
    const hashedPassword = await bcrypt.hash(userData.password, 10);

    const [result] = await pool.execute(
      `INSERT INTO users (name, email, password, accountNo, balance, currency, status, role) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userData.name,
        userData.email,
        hashedPassword,
        userData.accountNo,
        userData.balance || 0.0,
        userData.currency || 'USD',
        userData.status || 'Active',
        userData.role || 'client'
      ]
    );
    return { id: result.insertId, ...userData };
  },

  async findOne(query) {
    let sql = 'SELECT * FROM users WHERE ';
    const keys = Object.keys(query);
    const values = Object.values(query);
    sql += keys.map(key => `${key} = ?`).join(' AND ');
    sql += ' LIMIT 1';
    const [rows] = await pool.execute(sql, values);
    return rows[0] || null;
  },

  async findById(id) {
    const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [id]);
    return rows[0] || null;
  },

  async find() {
    const [rows] = await pool.execute('SELECT * FROM users');
    return rows;
  },

  async comparePassword(enteredPassword, hashedPassword) {
    return await bcrypt.compare(enteredPassword, hashedPassword);
  },

  async save(user) {
    await pool.execute(
      `UPDATE users SET balance = ?, status = ? WHERE id = ?`,
      [user.balance, user.status, user.id]
    );
    return user;
  },

  async setOtp(email, otp, expiresAt) {
    await pool.execute(
      `UPDATE users SET otpCode = ?, otpExpiresAt = ? WHERE email = ?`,
      [otp, expiresAt, email]
    );
  },

  async clearOtp(email) {
    await pool.execute(
      `UPDATE users SET otpCode = NULL, otpExpiresAt = NULL WHERE email = ?`,
      [email]
    );
  },

  // ---------- NEW: save the registration profile from the Flutter app ----------
  // If a user with this email already exists, update it. Otherwise create it.
  async saveProfile(email, p) {
    const fullName = `${p.firstName || ''} ${p.lastName || ''}`.trim();
    const existing = await User.findOne({ email });

    if (existing) {
      await pool.execute(
        `UPDATE users SET
           name = ?, first_name = ?, last_name = ?, gender = ?,
           birth_date = ?, id_type = ?, id_number = ?, id_expiry_date = ?,
           address = ?, photo_path = COALESCE(?, photo_path)
         WHERE email = ?`,
        [
          n(fullName), n(p.firstName), n(p.lastName), n(p.gender),
          n(p.birthDate), n(p.idType), n(p.idNumber), n(p.idExpiryDate),
          n(p.address), n(p.photoPath),
          email,
        ]
      );
      return await User.findOne({ email });
    }

    // New user: the table needs a password and an account number,
    // so create a random password (user logs in with OTP) and a unique account number.
    const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);

    let accountNo;
    do {
      accountNo = String(Math.floor(100000000000 + Math.random() * 900000000000));
    } while (await User.findOne({ accountNo }));

    const [result] = await pool.execute(
      `INSERT INTO users
         (name, email, password, accountNo, balance, currency, status, role,
          first_name, last_name, gender, birth_date, id_type, id_number,
          id_expiry_date, address, photo_path)
       VALUES (?, ?, ?, ?, 0, 'USD', 'Active', 'client', ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        n(fullName), email, hashedPassword, accountNo,
        n(p.firstName), n(p.lastName), n(p.gender), n(p.birthDate),
        n(p.idType), n(p.idNumber), n(p.idExpiryDate), n(p.address), n(p.photoPath),
      ]
    );
       return await User.findOne({ email });
  }
};

module.exports = User;