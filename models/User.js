const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');

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
  }
};

module.exports = User;