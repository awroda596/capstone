//adapted from simonsruggi on medium.com
// https://medium.com/@simonsruggi/jwt-authentication-with-node-js-and-mongodb-4f2c0a1b8e3d
const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  displayname: {type: String, required: true},  
  avatar: {
    type: String,
  },  //saves the fileid to the avatar, returned via get and post to /api/avatar/filename
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],  //user's tea reviews
  sessions: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],   //list of recorded tea sessions. 
  shelves: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }], //lists of teas for the user's cabinet
}, { timestamps: true });

//adapted from Dev Balaji, Medium

// Hash the password before saving the user model
userSchema.pre('save', async function (next) {
  const user = this;
  if (!user.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt();
    user.password = await bcrypt.hash(user.password, salt);
    next();
  } catch (error) {
    return next(error);
  }
});

//compare a given password with the hashed password in the database
userSchema.methods.comparePassword = async function (password) {
  return bcrypt.compare(password, this.password);
};


const User = mongoose.model("User", userSchema);

module.exports = User;