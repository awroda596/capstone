const express = require('express');
const mongoose = require('./db'); // Ensure this connects to MongoDB
const scrapeTeas = require('./webscraping');
const teaService = require('./tea.service');

const app = express();
const PORT = process.env.PORT || 3000;

// Function to scrape and update MongoDB
async function scrapeAndUpdateTeas() {
    try {
        console.log('Starting web scraping...');
        const teas = await scrapeTeas();
        console.log('Web scraping completed. Updating database...');
        await teaService.upsertTeas(teas);
        console.log('Database updated successfully.');
    } catch (error) {
        console.error('Error during scraping or database update:', error);
    }
}

// Run web scraping and database update at startup
scrapeAndUpdateTeas();

// Schedule web scraping every 24 hours (86400000 ms)
setInterval(scrapeAndUpdateTeas, 24 * 60 * 60 * 1000);

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
