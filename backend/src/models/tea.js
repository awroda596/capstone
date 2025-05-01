
const mongoose = require('mongoose');

const teaSchema = new mongoose.Schema({
  name: { type: String, required: true },
  link: { type: String, required: true },
  type: { type: String, default: 'N/A' },
  price: { type: String, default: 'N/A' },
  description: { type: String, default: null},
  tastingNotes: { type: String, default: null},
  vendor: { type: String, default: 'N/A' },
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],
  isScraped: { type: Boolean, default: false }, // to prevent user submitted teas from being overwritten. 
  isSoldOut: { type: Boolean, default: false }, // to mark teas that are sold out
});

const Tea = mongoose.model('Tea', teaSchema);

module.exports = Tea;
 