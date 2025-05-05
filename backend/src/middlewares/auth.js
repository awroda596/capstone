//adapted from Dev Balaji, Medium
const jwt = require('jsonwebtoken');
const User = require('../models/user.js');
const { getTimestamp } = require('../utils/timestamp.js');
// Middleware for authentication, checks for token and decodes if present
const authenticate = async (req, res, next) => {

  const ip = req.headers['x-forwarded-for'] || req.ip;
  
  console.log(`[${getTimestamp()}] Incoming request from: ${ip}`);
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) {
    console.log(`[${getTimestamp()}] no token provided for ${ip}`);
    return res.status(401).json({ message: 'Authentication required' });
  }

  try {
    const decodedToken = jwt.verify(token, process.env.SECRET_KEY);
    const user = await User.findById(decodedToken.userId);
    if (!user) {
      getTimestamp() = new Date().toISOString();
      console.log(`[${getTimestamp()}] user not found for ${ip}`);
      return res.status(404).json({ message: 'User not found' });
    }
    req.user = user;
    next();
  } catch (error) {
    console.log(`[${getTimestamp()}] invalid token for ${ip}`);
    res.status(401).json({ message: 'Invalid token' });
  }
};

module.exports = { authenticate };