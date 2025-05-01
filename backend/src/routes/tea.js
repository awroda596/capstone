// src/routes/teas.js

const express = require('express');
const Tea = require('../models/tea'); 
const router = express.Router();


router.get('/api/teas', async (req, res) => {
  try {
    const teas = await Tea.find();
    if (teas.length === 0) {
      return res.status(404).json({ message: 'No teas found' });
    }
    res.json(teas);
  } catch (error) {
    console.error("Error getting teas from MongoDB:", error);
    res.status(500).json({ error: 'Failed to retrieve teas' });
  }
});

module.exports = router; 
