const User = require('../models/User');
const Transaction = require('../models/Transaction');

exports.transferMoney = async (req, res) => {
  try {
    const { amount, recipientAccount } = req.body;
    const senderId = req.user.id;

    const sender = await User.findById(senderId);
    if (!sender || sender.balance < amount) {
      return res.status(400).json({ success: false, message: 'Insufficient balance or user not found.' });
    }

    sender.balance -= amount;
    await sender.save();

    const newTransaction = new Transaction({
      sender: sender._id,
      recipientAccount: recipientAccount,
      amount: amount,
      status: 'Completed',
      date: new Date()
    });

    await newTransaction.save();

    return res.status(200).json({
      success: true,
      message: 'Money transferred and recorded successfully!',
      transaction: newTransaction
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: err.message });
  }
};