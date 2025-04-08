const express = require('express');
const connectDB  = require('./src/config/db');  // Import the connectDB function
const {pushTeas} = require('./src/services/tea.service');  // Import the pushTeas function
const { scrapeInit } = require('./src/services/webscraping');  // Import the webScraper function
const app = express();
const teaRoutes = require('./src/routes/tea.routes');  // Import routes from tea.routes.js
const authRoutes = require('./src/routes/auth');  // Import routes from auth.js


const PORT = 3001;
const cors = require("cors"); // Import the CORS middleware
require("dotenv").config();


async function startServer() {
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
    // initial scrape and push
    console.log('Scraping teas...'); 
    let iteas = await scrapeInit();
    console.log('Upserting teas to MongoDB...');
    await pushTeas(iteas);

    //set up recurring scrape
    const SCRAPE_INTERVAL = 24 * 60 * 60 * 1000; // Scrape every 24 hours
    setInterval(async () => {
      console.log('Scraping teas...'); 
      let teas = await scrapeInit(); 
      console.log('Upserting teas to MongoDB...');
      await pushTeas(teas); 
    }, SCRAPE_INTERVAL);
  } catch (error) {
    console.error('Error:', error);
  }
}

app.listen(PORT, () => {
  console.log('Server is running on http://localhost:3001');
});
startServer();

// set up scraping

