const mongoose = require('mongoose');

const uri = "mongodb://localhost:27017/testdb"; // MongoDB connection string

async function connectDB() {
  try {
    await mongoose.connect(uri, {});
  } catch (error) {
    let timestamp = new Date().toISOString();
    console.error(`[${timestamp}] MongoDB connection error! exiting...`);
    process.exit(1); // kill app if failure
  }
}

module.exports = {connectDB, uri};