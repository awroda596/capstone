//adapted from simonsruggi on medium.com
// https://medium.com/@simonsruggi/jwt-authentication-with-node-js-and-mongodb-4f2c0a1b8e3d
require('dotenv').config(); // Load environment variables from .env file
const jwt = require('jsonwebtoken');
const SECRET_KEY = process.env.SECRET_KEY

const generateToken = (user) => {
    return jwt.sign({ id: user._id, email: user.email }, SECRET_KEY, {
        expiresIn: '1h'
    });
};
const verifyToken = (token) => {
    return jwt.verify(token, SECRET_KEY);
};
module.exports = { generateToken, verifyToken };