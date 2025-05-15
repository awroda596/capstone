//handler for user and user collections routes.  
//Right now also handles all the actual logic and stuff
// will separte it out as time permits.  

const express = require('express');
const { authenticate } = require('../middlewares/auth');
const router = express.Router();
const crypto = require('crypto');
const path = require('path');
const uri = require('../config/db.js');
const mongoose = require('mongoose');
const User = require('../models/user');
const Review = require('../models/review');
const Session = require('../models/session');
const Shelf = require('../models/shelf');
const { getTimestamp } = require('../utils/timestamp');
//check token

router.get('/', authenticate, async (req, res) => {
  try {
    console.log("incoming request for user info");
    const displayname = req.user.displayname;
    let avatar = null;
    if (req.user.avatar) {
      avatar = req.user.avatar;
    }
    let time = req.user.createdAt;
    res.status(200).json({ displayname, avatar, time });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// get reviews, paginated
router.get('/reviews', authenticate, async (req, res) => {
  console.log("requesting reviews!");
  console.log(req.query.pageSize);
  console.log(req.query.page);
  try {
    full = await Review.find({ _id: { $in: req.user.reviews } }); //find the reviews in the chosen slic
    console.log(full)
    res.json(full);
  } catch (err) {
    console.log(`Error ${err.message}`);
    res.status(500).json({ error: err.message });
  }
});

// user's sessions, with pagination logic
router.get('/sessions', authenticate, async (req, res) => {
  try {

    ;
    const full = await Session.find({ _id: { $in: req.user.sessions } });
    res.json(full);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



// POST /displayName - Authenticated update of displayName
router.post('/displayname', authenticate, async (req, res) => {
  const { displayname } = req.body;
  if (!displayname) return res.status(400).json({ error: 'Missing display name' });

  try {
    console.log("updating DisplayName to ", displayname);
    await User.findOneAndUpdate(
      { _id: req.user._id },
      { $set: { displayname } },
      { new: true }
    );
    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Error updating display name:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//  get and post avatar via encoding in base64
router.post('/avatar/upload', authenticate, async (req, res) => {
  try {
    console.log("trying to FUCKING UPLOAD GOD FUCKING DAMMIT");
    const { base64Image } = req.body;
    if (!base64Image) return res.status(400).json({ error: 'Missing image data' });

    await User.findByIdAndUpdate(req.user._id, {
      $set: { avatarBase64: base64Image }
    });

    res.status(200).json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



router.put('/reviews/:id', authenticate, async (req, res) => {
  const { reviewText, rating } = req.body;

  try {
    const updatedReview = await Review.findOneAndUpdate(
      { _id: req.params.id, _id: { $in: req.user.reviews } }, // secure: only user's review
      {
        $set: {
          ...(reviewText && { reviewText }),
          ...(rating !== undefined && { rating }),
        },
      },
      { new: true }
    );

    if (!updatedReview) {
      return res.status(404).json({ error: 'Review not found or not yours' });
    }

    res.json(updatedReview);
  } catch (err) {
    console.error('Error updating review:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/sessions', authenticate, async (req, res) => {
  try {
    const {
      teaName,
      teaVendor,
      sessionText,
      flavorNotes,
      brewWeight,
      brewVolume,
      brewTemp,
      brewTime,
    } = req.body;

    if (!sessionText) {
      return res.status(400).json({ error: 'Session text is required' });
    }

    const newSession = new Session({
      teaName,
      teaVendor,
      sessionText,
      flavorNotes,
      brewWeight,
      brewVolume,
      brewTemp,
      brewTime,
      user: req.user._id,
    });

    const saved = await newSession.save();

    await User.findByIdAndUpdate(req.user._id, {
      $push: { sessions: saved._id },
    });

    res.status(201).json(saved);
  } catch (err) {
    console.error('Error creating session:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//add a new shelf
router.post('/shelves', authenticate, async (req, res) => {
  const { shelfLabel } = req.body;

  if (!shelfLabel) {
    return res.status(400).json({ error: 'Shelf label is required' });
  }

  try {
    console.log("Trying to save");
    const newShelf = new Shelf({
      shelfLabel,
      teas: [],
    });

    const savedShelf = await newShelf.save();

    await User.findByIdAndUpdate(
      req.user._id,
      { $push: { shelves: savedShelf._id } },
      { new: true, useFindAndModify: false } // optional
    );

    console.log(savedShelf);
    res.status(200).json(savedShelf);
  } catch (err) {
    console.error('Error creating shelf:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

//new shelves route passing params by endpoint 
router.post ('/shelves/:shelfId/teas', authenticate, async (req,res) => {
  const {shelfId} = req.params; 
  const {teaId} = req.body; 
  console.log(`[${getTimestamp()}] Shelf Tea Addition Request`); 
  try {
    const shelf = await Shelf.findById(shelfId);
    if (!shelf) return res.status(404).json({ message: 'Shelf not found' });

    if (shelf.teas.includes(teaId)) {
      return res.status(200).json({ message: 'Tea already in shelf' });
    }

    shelf.teas.push(teaId);
    await shelf.save();
    res.status(200).json({ message: 'Tea added successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
});



router.get('/shelves', authenticate, async (req, res) => {
  try {
    user = req.user; 
    if (!req.user) {
      console.log("NO USER"); 
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('User shelves:', user.shelves);

    if (!user.shelves || user.shelves.length === 0) return res.json([]);

    const shelves = await Shelf.find({ _id: { $in: user.shelves } }).populate('teas');
    
    console.log('Fetched shelves:', shelves);

    const formatted = shelves.map(shelf => ({
      _id: shelf._id,
      shelfLabel: shelf.shelfLabel,
      teas: shelf.teas
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Shelf GET error:', err.message);
    console.error(err.stack);
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;

