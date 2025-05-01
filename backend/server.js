const express = require('express');
const fs = require('fs');
const https = require('https');
const app = express();
const connectDB  = require('./src/config/db');  // Import the connectDB function
const { scrapeTeas } = require('./src/services/webscraping');  // Import the webScraper function
const teaRoutes = require('./src/routes/tea');  
const authRoutes = require('./src/routes/auth');  
const userRoutes = require('./src/routes/user');
const { getTimestamp } = require('./src/utils/timestamp'); // Import the getTimestamp function

const cors = require("cors"); // Import the CORS middleware
require("dotenv").config();


async function startServer() {
    // Connect to MongoDB
    console.log(`[${getTimestamp()}] connecting to MongoDB...`);
    await connectDB();
    console.log(`[${getTimestamp()}] MongoDB connected successfully!`);

    //Initial scrape
    console.log(`[${getTimestamp()}] Initial Server start scrape...`);
    await scrapeTeas(); 
    console.log(`[${getTimestamp()}] Initial scrape completed!`);
    //interval scraping
    const SCRAPE_INTERVAL = 24 * 60 * 60 * 1000; // Scrape every 24 hours
    setInterval(async () => {
      console.log(`[${getTimestamp()}] Scraping teas...`);
      await scrapeTeas();  
    }, SCRAPE_INTERVAL);
}

app.use(express.json());
app.use(cors());

//Routes
app.use('/auth', authRoutes);
app.use('/user', userRoutes);
app.use('/teas', teaRoutes); 


console.log(`[${getTimestamp()}] Starting server on port 443...`);
https.createServer({
  cert: fs.readFileSync('./localhost.crt'),
  key: fs.readFileSync('./localhost.key')
}, (req, res) => {
  res.writeHead(200);
  res.end('Hello from Node!\n');
}).listen(443);
console.log(`[${getTimestamp()}] HTTPS server running on port 443`);
startServer();

// set up scraping

