const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  txnId: { 
    type: String, 
    required: true, 
    unique: true 
  },
  senderAccount: { 
    type: String, 
    required: true 
  },
  recipientAccount: { 
    type: String, 
    required: true 
  },
  amount: { 
    type: Number, 
    required: true 
  },
  type: { 
    type: String, 
    enum: ['Transfer', 'Bill Payment', 'Deposit', 'Withdrawal'], 
    default: 'Transfer' 
  },
  status: { 
    type: String, 
    enum: ['Pending', 'Completed', 'Failed'],
    default: 'Completed' 
  },
  date: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Transaction', transactionSchema);