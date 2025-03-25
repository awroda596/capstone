const { MongoClient } = require("mongodb");
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');


const uri = "mongodb://localhost:27017/testdb"; // MongoDB connection string

const client = new MongoClient(uri);

async function connectDB() {
  try {
    await mongoose.connect(uri, {
    });
    console.log("Connected to MongoDB with Mongoose");
  } catch (error) {
    console.error("MongoDB connection error:", error);
  }
}

const reviewSchema = new mongoose.Schema({
  user: { type: String, required: true },
  rating: { type: Number, required: true, min: 1, max: 10 },
  Notes: { type: String, required: true },
  comment: { type: String, required: true },
  date: { type: Date, default: Date.now },
  tea: { type: mongoose.Schema.Types.ObjectId, ref: 'Tea', required: true },  // Reference to the Tea
});


const teaSchema = new mongoose.Schema({
  name: { type: String, required: true },
  link: { type: String, required: true },
  origin: { type: String, default: 'Unknown' },
  notes: { type: String, default: 'Unknown' },
  description: { type: String, default: 'Unknown' },
  vendor: { type: String, default: 'Unknown' },
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],
});

const Review = mongoose.model('Review', reviewSchema);
const Tea = mongoose.model('Tea', teaSchema);


const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  password: { type: String, required: true },
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],
});

//save password as hash
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
});

//compare password
userSchema.methods.matchPassword = async function(password) {
  return await bcrypt.compare(password, this.password);
};

const User = mongoose.model('User', userSchema);



async function pushTeas(teas) {
  console.log("Upserting teas to MongoDB...");
  try {
    for (let tea of teas) {
      console.log(`Upserting tea: ${JSON.stringify(tea)}`);
      await Tea.findOneAndUpdate(
        { name: tea.name }, // Match by name
        { 
          name: tea.name,
          link: tea.link,
          vendor: tea.vendor,
          price: tea.price 
        }, // Update fields
        { upsert: true, new: true } // Create if not exists, return the new document
      );
    }
  } catch (error) {
    console.error("Error upserting teas to MongoDB:", error);
  }
}

async function getTeas() {
  try {
    const teas = await Tea.find({});
    return teas;
  } catch (error) {
    console.error("Error getting teas from MongoDB:", error);
  }
}

module.exports = { connectDB, client, pushTeas, getTeas };


