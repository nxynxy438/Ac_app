const express = require('express');
const router = express.Router();

const clientController = require('../controllers/clientController');
const adminController = require('../controllers/adminController');
const transactionController = require('../controllers/transactionController');

// Optional Auth Bypass / Mock Middleware for safe testing
const optionalAuth = (req, res, next) => {
  req.user = { id: 'mock-user-id', role: 'client' };
  next();
};

// ==========================================
// CLIENT API ROUTES
// ==========================================
router.get('/client/dashboard', optionalAuth, clientController.getClientDashboard);
router.post('/client/transfer', optionalAuth, transactionController.transferMoney);
router.post('/client/pay-bill', optionalAuth, clientController.payBill);

// ==========================================
// ADMIN API ROUTES
// ==========================================
router.get('/admin/users', adminController.getUsers);
router.post('/admin/users/toggle-status', adminController.toggleUserStatus);
router.get('/admin/logs', adminController.getLogs);

module.exports = router;