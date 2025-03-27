const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: { type: String, required: true },
  rating: { type: Number, required: true, min: 1, max: 10 },
  Notes: { type: String, required: true },
  comment: { type: String, required: true },
  date: { type: Date, default: Date.now },
  tea: { type: mongoose.Schema.Types.ObjectId, ref: 'Tea', required: true },
});

const Review = mongoose.model('Review', reviewSchema);

module.exports = Review;