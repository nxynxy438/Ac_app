const express = require('express');
const router = express.Router();
const db = require('../db'); // Your existing database connector module

// API Endpoint to store incoming mobile app transactions
router.post('/api/transactions/log', (req, res) => {
    const { txn_id, amount, account_number, type, phone_number, created_at } = req.body;
    
    console.log(`[API Log] Received ${type} transaction: ${txn_id}`);

    // Adjust column names to match your existing MySQL schema constraints
    const sql = `INSERT INTO transaction_history 
                 (txn_id, amount, account_number, type, phone_number, date_time) 
                 VALUES (?, ?, ?, ?, ?, ?)`;

    db.query(sql, [txn_id, amount, account_number, type, phone_number, created_at], (err, result) => {
        if (err) {
            console.error("Failed to insert transaction log:", err);
            return res.status(500).json({ success: false, error: err.message });
        }
        res.status(200).json({ success: true, message: "Transaction stored successfully" });
    });
});

// Admin Panel View: Render the list onto history-transaction.ejs
router.get('/admin/history-transaction', (req, res) => {
    const sql = "SELECT * FROM transaction_history ORDER BY id DESC";
    db.query(sql, (err, results) => {
        if (err) throw err;
        res.render('admin/history-transaction', { transactions: results });
    });
});

module.exports = router;
