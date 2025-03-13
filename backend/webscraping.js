const { chromium } = require('playwright');
const { pushTeas } = require('./mongo');

async function scrape() {
  // Launch browser
  const browser = await chromium.launch({ headless: true }); // Change to `true` for headless mode

  // List of URLs to scrape
  const urls = [
   // 'https://redblossomtea.com/collections/oolong',
    'https://redblossomtea.com/collections/white',
   // 'https://redblossomtea.com/collections/black',
    //'https://redblossomtea.com/collections/pu-erh',
    //'https://redblossomtea.com/collections/green',
  ];

  // Loop through each category URL
  let accumTeas = [];
  for (let url of urls) {
    let pageNum = 1;
    const page = await browser.newPage();
    await page.goto(url);

    //while looping through pages for url
    while (true) {

      await page.waitForSelector('.product');
      const teas = await page.$$eval('.product', (productElements) => {
        return productElements
          .map((productElement) => {
            const nameElement = productElement.querySelector('.product-card-details .title a');
            const name = nameElement ? nameElement.textContent.trim() : null;
            const link = nameElement ? nameElement.href : null;
            return { name, link };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('collection')); // Filter out products with "collection" in the title
      });

      for (let tea of teas) {
        if (tea.link) {
          const productPage = await browser.newPage();
          await productPage.goto(tea.link);

          console.log(`Navigating to ${tea.link} for ${tea.name}...`);
          await productPage.waitForSelector('.product-details');

          try {
            const origin = await productPage.$eval(
              '.tea-description-container .tea-description td:nth-child(2) span:last-child',
              el => el.textContent.trim()
            ).catch(() => "Unknown");;

            const notes = await productPage.$eval(
              '.tea-description-container .tea-description td:nth-child(4) span:last-child',
              el => el.textContent.trim()
            ).catch(() => "Unknown");;

            /*
            const description = await productPage.$$eval(
              '#p-des-shortcut .module.description .rte .tabs-content li p', 
              (paragraphs) => {
                // Join all paragraphs found with a period and space, or return "Unknown" if none found
                return paragraphs.length > 0 
                  ? paragraphs.map((p) => p.textContent.trim()).join('. ') 
                  : "Unknown";
              }
            ).catch(() => "Unknown");
            */

            tea.origin = origin;
            tea.notes = notes;
            tea.description = '';
            tea.vendor = 'Red Blossom Tea Company';
            tea.reviews = [];
            console.log(`Scraped Tea:`, tea);

          } catch (error) {
            console.error(`Error scraping product ${tea.link}:`, error);
          }

          await productPage.close(); 

        }//if tea has link
      }

      
      accumTeas = accumTeas.concat(teas);

      // check for next page
      const nextPageLink = await page.$('.pagination li.next a');  // Check for the <a> inside <li class="next">
      if (nextPageLink) {
        console.log('checking for next page');
        const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
        await page.goto(nextPageUrl);  
        pageNum++; 
        console.log(`Navigating to page ${pageNum}...`);
        const currentUrl = await page.url();
        console.log('Current page URL:', currentUrl);
        await page.waitForTimeout(2000); // Wait for the next page to load
      } else {
        console.log('No more pages to scrape.');
        break;  // Exit While() loop
      }
    }
    await page.close(); // Close the current page after scraping
  }

  await browser.close(); 
  return accumTeas;
}




module.exports = { scrape };