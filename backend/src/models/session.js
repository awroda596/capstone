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
  flavorNotes: {type: String},
  brewTemp: {type: String},
  brewWeight: {type: String},
  brewVolume:{type: String},
  brewTime: {type: String},
}, { timestamps: true });

const Session = mongoose.model('Session', sessionSchema);

module.exports = Session;
 