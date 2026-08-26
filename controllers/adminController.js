const User = require('../models/User');
const AuditLog = require('../models/AuditLog');

const getUsers = async (req, res) => {
  try {
    const users = await User.find();
    return res.json({ success: true, users });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

const toggleUserStatus = async (req, res) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(userId);
    if (user) {
      user.status = user.status === 'Active' ? 'Frozen' : 'Active';
      await user.save();
    }
    return res.json({ success: true, user });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

const getLogs = async (req, res) => {
  try {
    const logs = await AuditLog.find();
    return res.json({ success: true, logs });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

module.exports = {
  getUsers,
  toggleUserStatus,
  getLogs
};