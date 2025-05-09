//handle routing for teas with logic delegated to services and controllers.  If handled here, will be split into those files time permitting. 
const express = require('express');
const Tea = require('../models/tea');
const Review = require('../models/review');
const router = express.Router();
const { getTeas, findTeas} = require('../services/tea.js');
const { authenticate } = require('../middlewares/auth.js');
const { getTimestamp } = require('../utils/timestamp.js');
const User = require('../models/user');

// search for tea documents matching the structured query from flutter.  return the results
// use post since we're posting a query to it
router.post('/search', async (req, res) => {
  try {
    const { search = "", filters = {}, offset, limit } = req.body;
    const result = await findTeas({ search, filters, offset, limit });
    res.json(result);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


//deprecated search. may maintain for simpler tea retrieval functions 
router.get('/search', async (req, res) => {
  try {
    const { query, type, vendor, offset, limit } = req.query;
    const result = await getTeas({ query, type, vendor, offset, limit });
    res.json(result);
  } catch (err) {
    console.error('Search failed:', err);
    res.status(500).json({ error: 'Search failed' });
  }
});

// get reviews for a specific tea 
router.get('/reviews', authenticate, async (req, res) => {
  try {
    //get teaid from query
    const { tea } = req.query;
    if (!tea) return res.status(400).json({ message: 'Tea ID required' });

    const teaDoc = await Tea.findById(tea).populate({
      path: 'reviews',
      populate: { path: 'user', select: 'username' },
      options: { sort: { date: -1 } }
    });

    if (!teaDoc) return res.status(404).json({ message: 'Tea not found' });

    const formatted = teaDoc.reviews.map(review => ({
      _id: review._id,
      rating: review.rating,
      notes: review.notes,
      reviewText: review.reviewText,
      date: review.date,
      tea: review.tea,
      teaName: review.teaName,
      teaVendor: review.teaVendor,
      username: review.user?.username || 'Unknown'
    }));

    res.status(200).json(formatted);
  } catch (err) {
    console.error('Failed to fetch reviews:', err);
    res.status(500).json({ message: 'Failed to fetch reviews' });
  }
});

// upsert a review
router.post('/reviews', authenticate, async (req, res) => {
  console.log(`[${getTimestamp()}] Tea Review Submission attempt`);

  try {
    const { rating, reviewText, notes, tea } = req.body;

    const teaDoc = await Tea.findById(tea);
    if (!teaDoc) {
      console.log(`[${getTimestamp()}] could not find tea!!!`);
      return res.status(404).json({ message: 'Tea not found' });
    }

    const review = await Review.findOneAndUpdate(
      { user: req.user._id, tea },
      {
        $set: {
          rating,
          reviewText,
          notes,
          teaName: teaDoc.name,
          teaVendor: teaDoc.vendor
        },
        $setOnInsert: {
          user: req.user._id,
          tea
        }
      },
      { new: true, upsert: true }
    );

    //add to the references for the tea, and for the User. 
    await Tea.findByIdAndUpdate(tea, {
      $addToSet: { reviews: review._id }
    });

    await User.findByIdAndUpdate(req.user._id, {
      $addToSet: { reviews: review._id }
    });

    const reviews = await Review.find({ tea, rating: { $ne: null } });
    const avgRating =
      reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length;

    await Tea.findByIdAndUpdate(tea, {
      rating: avgRating,
      numRatings: reviews.length
    });

    res.status(201).json(review);
  } catch (err) {
    console.error(`[${getTimestamp()}] Error submitting review:`, err);
    res.status(500).json({ message: 'Server error' });
  }
});




module.exports = router;
