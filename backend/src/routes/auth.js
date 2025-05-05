const express = require('express');
const { register, login } = require('../controllers/auth');
const {authenticate} = require('../middlewares/auth.js'); 

const router = express.Router();
router.get('/auth', authenticate, (req, res) => {
    console.log()
    res.json({ message: `Welcome ${req.user.username}` });
  });


router.post('/register', register);
router.post('/login', login);


module.exports = router;