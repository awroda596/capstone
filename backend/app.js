const express = require('express');
const { connectDB } = require('./src/config/db');  // Import the connectDB function
const {pushTeas} = require('./src/services/tea.service');  // Import the pushTeas function
const { scrapeInit } = require('./src/services/webscraping');  // Import the webScraper function
const app = express();


async function scrapeAndPushTeas(){
  let teas = [];
  try {
    console.log('Starting web scraping...');
    teas = await scrapeInit();
  } catch (error) {
    console.error('Error during scraping or database update:', error);
  }
  try {
    await pushTeas(teas);
    console.log('Database updated successfully.');
  } catch(error) {
    console.error('Error updating database:', error);
  }
}

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
    console.error('Error:', error);
  }
}

app.listen(3000, () => {
  console.log('Server is running on http://localhost:3000');
});

// set up scraping

