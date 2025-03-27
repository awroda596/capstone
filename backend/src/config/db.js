const mongoose = require('mongoose');

const uri = "mongodb://localhost:27017/testdb"; // MongoDB connection string

async function connectDB() {
  try {
    await mongoose.connect(uri, {});
    console.log("Connected to MongoDB with Mongoose");
  } catch (error) {
    console.error("MongoDB connection error:", error);
  }
}

module.exports = connectDB;