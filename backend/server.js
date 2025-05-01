const express = require('express');
const fs = require('fs');
const https = require('https');
const app = express();
const connectDB  = require('./src/config/db');  // Import the connectDB function
const { scrapeTeas } = require('./src/services/webscraping');  // Import the webScraper function
const teaRoutes = require('./src/routes/tea');  
const authRoutes = require('./src/routes/auth');  
const userRoutes = require('./src/routes/user');

const cors = require("cors"); // Import the CORS middleware
require("dotenv").config();


async function startServer() {
  console.log('Starting server...');
  try {
    await connectDB();
    console.log('MongoDB connected successfully!');

    // Middleware for parsing JSON bodies
    app.use(cors());
    app.use(express.json());
    app.use("/api/auth", authRoutes);
    // API endpoint to get all teas
    app.get('/api/teas', async (req, res) => {
      try {
        const teas = await Tea.find({});
        res.json(teas); 
      } catch (error) {
        console.error("Error getting teas from MongoDB:", error);
        res.status(500).json({ error: 'Failed to retrieve teas' });
      }
    });

    console.log('Scraping teas...'); 
    await scrapeTeas(); // Initial scrape
    const SCRAPE_INTERVAL = 24 * 60 * 60 * 1000; // Scrape every 24 hours
    setInterval(async () => {
      console.log('Scraping teas...'); 
      await scrapeTeas();  
    }, SCRAPE_INTERVAL);
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    console.error('Error:', error);
  }
}



// Parse JSON request body
app.use(express.json());

//Routes
app.use('/auth', authRoutes);
app.use('/user', userRoutes);
app.use('/teas', teaRoutes); // Use the tea routes


console.log('Server is running on port 443...');
https.createServer({
  cert: fs.readFileSync('./localhost.crt'),
  key: fs.readFileSync('./localhost.key')
}, (req, res) => {
  res.writeHead(200);
  res.end('Hello from Node!\n');
}).listen(443);
startServer();

// set up scraping

