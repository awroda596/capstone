//script for testing site scraping
const { chromium } = require('playwright');
const { getTeaInfo } = require('./src/services/webscraping.js');
const {redBlossomTeaScrapeSelectors} = require('./src/config/webscraping.js');
const {sites} = require('./src/config/webscraping.js');
const {getUndescribedTeas, updateTea} = require('./src/services/tea.js');
const connectDB  = require('./src/config/db');  


(async () => {
  await connectDB(); // Connect to MongoDB
  const browser = await chromium.launch();
  const page = await browser.newPage();

  let teas = await getUndescribedTeas(); //get all teas that are not described yet

  await getTeaInfo(teas, browser);






 

  await browser.close();
})();