//script for testing site scraping
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Go to the page you want to scrape
  await page.goto('https://redblossomtea.com/collections/oolong');
  // Wait for the products to load
  await page.waitForSelector('.page-body-content'); 
  // Scrape the data
  const teas = await page.$$eval('.page-body-content .product-list.row-of-4 li', (productElements) => {
    return productElements.map((productElement) => {
      const nameElement = productElement.querySelector('.product-card-details h2.title a');
      const priceElement = productElement.querySelector('.product-card-details .price .money');
      const name = nameElement ? nameElement.textContent.trim() : null;
      const price = priceElement ? priceElement.textContent.trim() : null;
      return { name, price };
    });
  });

  console.log(teas); // Output the scraped data

  await browser.close();
})();