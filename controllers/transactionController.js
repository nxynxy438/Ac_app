const User = require('../models/User');
const Transaction = require('../models/Transaction');

exports.transferMoney = async (req, res) => {
  try {
    const { amount, recipientAccount } = req.body;
    const transferAmt = parseFloat(amount);

    if (!req.user || !req.user.id) {
      return res.status(401).json({ success: false, message: 'Not authenticated' });
    }

    const sender = await User.findById(req.user.id);

    if (!sender || sender.balance < transferAmt) {
      return res.status(400).json({ success: false, message: 'Insufficient balance or user not found.' });
    }

    const newBalance = sender.balance - transferAmt;
    await User.save({ id: sender.id, balance: newBalance, status: sender.status });

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