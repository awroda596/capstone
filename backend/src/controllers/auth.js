//adapted from Dev Balaji, Medium
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const User = require('../models/user.js');
const { getTimestamp } = require('../utils/timestamp.js');
// Register a new user
const register = async (req, res, next) => {
  const { username, email, password } = req.body;
  const displayname = username
  try {
    const user = new User({ username, email, password, displayname }); 
    await user.save(); 
    console.log(`[${getTimestamp()}] User registered: ${user.username}, ${user.email}`);
    res.status(200).json({ message: 'Registration successful' });
  } catch (error) {
    console.error(`[${getTimestamp()}] Error registering user: ${error.message}`);
    if (error.code === 11000) {
      const duplicateField = Object.keys(error.keyPattern)[0];

      let message = 'Duplicate field error';
      if (duplicateField === 'username') {
        message = 'Username already exists';
      } else if (duplicateField === 'email') {
        message = 'Email is already in use';
      }
      return res.status(409).json({ success: false, message });
    }
    else{
      console.error(`[${getTimestamp()}] Error registering user: ${error.message}`);
    }
  }
}

// Login with an existing user
const login = async (req, res, next) => {
  const { username, password } = req.body;
  console.log(`[${getTimestamp()}] Login attempt for user: ${username}`);
  try {
    const user = await User.findOne({ username });
    if (!user) {
      console.error(`[${getTimestamp()}] Error: User not found for ${username}`);
      return res.status(401).json({ message: 'Incorrect Credentials' });
    }

    const passwordMatch = await user.comparePassword(password);
    if (!passwordMatch) {

      console.error(`[${getTimestamp()}] Error: Incorrect password for ${username}`);
      return res.status(401).json({ message: 'Incorrect Credentials' });
    }
    console.log(`[${getTimestamp()}] User logged in: ${user.username}`);
    const token = jwt.sign({ userId: user._id }, process.env.SECRET_KEY, {
      expiresIn: '1 hour'
    });
    res.json({ token });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login };