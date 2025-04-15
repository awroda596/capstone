
const mongoose = require('mongoose');

const teaSchema = new mongoose.Schema({
  name: { type: String, required: true },
  link: { type: String, required: true },
  type: { type: String, default: 'Unknown' },
  price: { type: String, default: 'Unknown' },
  description: { type: String, default: 'Unknown' },
  vendor: { type: String, default: 'Unknown' },
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],
});

const Tea = mongoose.model('Tea', teaSchema);

module.exports = Tea;