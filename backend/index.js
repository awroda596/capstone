const express = require('express');
const { connectDB } = require('./mongo');  // Import the connectDB function
const {pushTeas} = require('./mongo');  // Import the pushTeas function
const { getTeas } = require('./mongo');  // Import the getTeas function
const { scrapeInit } = require('./webscraping');  // Import the webScraper function
const app = express();
const {teaDB} = require('./mongo');


async function startServer() {
  try {
    await connectDB();
    console.log('MongoDB connected successfully!');

    // Middleware for parsing JSON bodies
    app.use(express.json());

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
    

    app.listen(3000, () => {
      console.log('Server is running on http://localhost:3000');
    });

    // initial scrape and push
    let iteas = await scrapeInit();
    console.log(iteas);
    await pushTeas(iteas);
    //set up recurring scrape
    const SCRAPE_INTERVAL = 24 * 60 * 60 * 1000; // Scrape every 24 hours
    setInterval(async () => {
      let teas = await scrapeInit(); // Run scraping asynchronously
      await pushTeas(teas); // Push the scraped teas to the database
    }, SCRAPE_INTERVAL);


    
  } catch (error) {
    console.error('Error starting server:', error);
  }


}

startServer();

// set up scraping

