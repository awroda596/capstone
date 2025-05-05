const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, //user who wrote the review
  rating: { type: Number, required: true, min: 1, max: 10 },
  notes: { type: String, default: null }, //flavor notes
  reviewText: { type: String, default: null },
  date: { type: Date, default: Date.now },
  tea: { type: mongoose.Schema.Types.ObjectId, ref: 'Tea',},
  teaName: { type: String },
  teaVendor: { type: String }
}, { timestamps: true });

const Review = mongoose.model('Review', reviewSchema);
module.exports = Review;