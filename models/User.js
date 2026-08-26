const { pool } = require('../config/db');
const bcrypt = require('bcryptjs');

const User = {
  // 📝 1. Create a new user (with password hashing)
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

  // 🔍 2. Find one user (supports queries like { role: 'client' } or { email: '...' })
  async findOne(query) {
    let sql = 'SELECT * FROM users WHERE ';
    const keys = Object.keys(query);
    const values = Object.values(query);

    sql += keys.map(key => `${key} = ?`).join(' AND ');
    sql += ' LIMIT 1';

    const [rows] = await pool.execute(sql, values);
    return rows[0] || null;
  },

  // 🆔 3. Find user by ID
  async findById(id) {
    const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [id]);
    return rows[0] || null;
  },

  // 📋 4. Get all users (used for admin dashboard)
  async find() {
    const [rows] = await pool.execute('SELECT * FROM users');
    return rows;
  },

  // 🔑 5. Compare entered password with hashed password
  async comparePassword(enteredPassword, hashedPassword) {
    return await bcrypt.compare(enteredPassword, hashedPassword);
  }
};

module.exports = User;