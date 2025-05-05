const mongoose = require('mongoose');
//for the user to log their tea sessions. 
const sessionSchema = new mongoose.Schema({
  tea: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Tea',
  },
  teaName:{type: String, required: true}, 
  teaVendor: {type: String}, 
  sessionText: {
    type: String,
    required: true
  },
  temperature: String,
  weight: String,
  volume: String,
  steep: String
}, { timestamps: true });

const Session = mongoose.model('Session', sessionSchema);

module.exports = Session;
 