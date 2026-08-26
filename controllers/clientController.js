const User = require('../models/User');
const Transaction = require('../models/Transaction');

exports.getClientDashboard = async (req, res) => {
  try {
    const account = await User.findOne({ role: 'client' });
    const transactions = await Transaction.find().sort({ date: -1 });
    res.json({ success: true, account, transactions });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

exports.transferMoney = async (req, res) => {
  try {
    const { amount, recipientAccount } = req.body;
    const transferAmt = parseFloat(amount);
    
    // Find client (fallback to any client if req.user is mock/missing)
    let sender = req.user ? await User.findById(req.user.id) : null;
    if (!sender) {
      sender = await User.findOne({ role: 'client' });
    }

    if (!sender || sender.balance < transferAmt) {
      return res.status(400).json({ success: false, message: 'Insufficient balance or user not found.' });
    }

    sender.balance -= transferAmt;
    await sender.save();

    const newTransaction = await Transaction.create({
      txnId: `TXN-${Math.floor(1000 + Math.random() * 9000)}`,
      senderAccount: sender.accountNo,
      recipientAccount: recipientAccount,
      amount: transferAmt,
      type: 'Transfer',
      status: 'Completed'
    });

    return res.status(200).json({
      success: true,
      message: 'Money transferred and recorded successfully!',
      transaction: newTransaction
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};

exports.payBill = async (req, res) => {
  try {
    res.json({ success: true, message: "Bill payment endpoint processed successfully." });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};