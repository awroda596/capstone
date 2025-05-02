const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const User = require('../models/user.js');

// Register a new user
const register = async (req, res, next) => {
  const { username, email, password } = req.body;

  try {
    const user = new User({ username, email, password }); // 🔥 No hashing here
    await user.save(); // ✅ Triggers the schema's pre-save to hash
    console.log('User registered:', user);
    res.json({ message: 'Registration successful' });
  } catch (error) {
    console.error('Error registering user:', error);
    next(error);
  }
}
// Login with an existing user
const login = async (req, res, next) => {
  const { username, password } = req.body;

  try {
    const user = await User.findOne({ username });
    if (!user) {
      console.error('User not found for', username);
      return res.status(404).json({ message: 'User not found' });
    }

    const passwordMatch = await user.comparePassword(password);
    if (!passwordMatch) {

      console.error('Incorrect password');
      return res.status(401).json({ message: 'Incorrect password' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.SECRET_KEY, {
      expiresIn: '1 hour'
    });
    res.json({ token });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login };