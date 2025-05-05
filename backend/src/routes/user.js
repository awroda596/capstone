const express = require('express');
const { authenticate } = require('../middlewares/auth');
const multer = require('multer');
const router = express.Router();
const crypto = require('crypto');
const path = require('path');
const Grid = require('gridfs-stream');
const { GridFsStorage } = require('multer-gridfs-storage');
const uri = require('../config/db.js');
const mongoose = require('mongoose');
const User = require('../models/user');
const Review = require('../models/review');
const Session = require('../models/session');
const Shelf = require('../models/shelf');
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

//  users tea "shelves" for their cabinet, paginated.  
router.get('/shelves', authenticate, async (req, res) => {
  const page = parseInt(req.query.page) || 0;
  const pageSize = parseInt(req.query.pageSize) || 2;
  try {
    const user = await User.findById(req.userId).select('shelves');
    const slice = user.shelves.slice(page * pageSize, (page + 1) * pageSize);
    const full = await Shelf.find({ _id: { $in: slice } }).populate('shelfLabel');
    const formatted = {};
    full.forEach(shelf => formatted[shelf.shelfLabel] = shelf.teas.map(t => t.name));
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const conn = mongoose.connection;
let gfs;
conn.once('open', () => {
  gfs = Grid(conn.db, mongoose.mongo);
  gfs.collection('avatars');
});

const storage = new GridFsStorage({
  url: uri,
  file: (req, file) => {
    return new Promise((resolve, reject) => {
      crypto.randomBytes(16, (err, buf) => {
        if (err) return reject(err);
        const filename = buf.toString('hex') + path.extname(file.originalname);
        resolve({ filename, bucketName: 'avatars' });
      });
    });
  }
});

const upload = multer({ storage });


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

// GET /avatar/:filename - Stream from GridFS
router.get('/avatar/:filename', async (req, res) => {
  try {
    const db = mongoose.connection.db;
    const bucket = new GridFSBucket(db, { bucketName: 'avatars' });
    const stream = bucket.openDownloadStreamByName(req.params.filename);

    stream.on('error', () => res.status(404).json({ error: 'File not found' }));
    stream.pipe(res);
  } catch (err) {
    console.error('Error streaming avatar:', err);
    res.status(500).json({ error: 'Server error' });
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

router.get('/shelves', authenticate, async (req, res) => {
  console.log("has to hit this"); 
  try {

    console.log (test); 
    if (!req.user) {
      console.log("NO USER"); 
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('User shelves:', user.shelves);

    if (!user.shelves || user.shelves.length === 0) return res.json([]);

    const shelves = await Shelf.find({ _id: { $in: user.shelves } }).populate('teas', 'name');

    console.log('Fetched shelves:', shelves);

    const formatted = shelves.map(shelf => ({
      _id: shelf._id,
      shelfLabel: shelf.shelfLabel,
      teas: shelf.teas.map(t => t.name),
    }));

    res.json(formatted);
  } catch (err) {
    console.error('Shelf GET error:', err.message);
    console.error(err.stack);
    res.status(500).json({ error: err.message });
  }
});
module.exports = router;

