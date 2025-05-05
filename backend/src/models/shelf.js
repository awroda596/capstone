const mongoose = require('mongoose');

const shelfSchema = new mongoose.Schema({
  shelfLabel: {
    type: String,
    required: true
  },
  teas: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tea'
  }]
}, { timestamps: true });

const Shelf = mongoose.model('Shelf', shelfSchema);

module.exports = Shelf;
 