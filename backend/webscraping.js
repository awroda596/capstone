const { chromium } = require('playwright');
const { pushTeas } = require('./mongo');

async function scrapeInit() {
  // Launch browser
  

  // List of URLs to scrape


  // Loop through each category URL
  let accumTeas = [];
  await redblossomtea(accumTeas);
  await ecoCha(accumTeas);
  return accumTeas;
}

async function redblossomtea(accumTeas)
{
  const browser = await chromium.launch({ headless: true }); 
  const urls = [
    // 'https://redblossomtea.com/collections/oolong',
      'https://redblossomtea.com/collections/white',
    // 'https://redblossomtea.com/collections/black',
     //'https://redblossomtea.com/collections/pu-erh',
     //'https://redblossomtea.com/collections/green',
   ];
  for (let url of urls) {
    let pageNum = 1;
    const page = await browser.newPage();
    await page.goto(url);
    //while looping through pages for url
    while (true) {
      await page.waitForSelector('.product');
      let type = null;
      switch (true) {
        case url.includes('oolong'):
        type = 'oolong';
        break;
        case url.includes('white'):
        type = 'white';
        break;
        case url.includes('black'):
        type = 'black';
        break;
        case url.includes('green'):
        type = 'green';
        break;
        case url.includes('pu-erh'):
        type = 'pu-erh';
        break;
      }
      const teas = await page.$$eval('.product', (productElements, type) => {
        return productElements
          .map((productElement) => {
        const nameElement = productElement.querySelector('.product-card-details .title a');
        const priceElement = productElement.querySelector('.product-card-details .price .money');
        const name = nameElement ? nameElement.textContent.trim() : null;
        const link = nameElement ? nameElement.href : null;
        const price = priceElement ? priceElement.textContent.trim() : null;

        return { name, type, link, price };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('collection')); // Filter out products with "collection" in the title
      }, type);
      for (let tea of teas) {
        console.log(`Scraped Tea:`, tea);
      }
      /*
      for (let tea of teas) {
        if (tea.link) {
          const productPage = await browser.newPage();
          await productPage.goto(tea.link);

          console.log(`Navi      await page.waitForSelector('.product');
      let type = null;
      switch (true) {
        case url.includes('oolong'):
        type = 'oolong';
        break;
        case url.includes('white'):
        type = 'white';
        break;
        case url.includes('black'):
        type = 'black';
        break;
        case url.includes('green'):
        type = 'green';
        break;
        case url.includes('pu-erh'):
        type = 'pu-erh';
        break;
      }
      const teas = await page.$$eval('.product', (productElements, type) => {
        return productElements
          .map((productElement) => {
        const nameElement = productElement.querySelector('.product-card-details .title a');
        const priceElement = productElement.querySelector('.product-card-details .price .money');
        const name = nameElement ? nameElement.textContent.trim() : null;
        const link = nameElement ? nameElement.href : null;
        const price = priceElement ? priceElement.textContent.trim() : null;

        return { name, type, link, price };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('collection')); // Filter out products with "collection" in the title
      }, type);gating to ${tea.link} for ${tea.name}...`);
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
      */
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
}
async function ecoCha(accumTeas)
{
  const browser = await chromium.launch({ headless: true }); 
  const urls = [
    'https://eco-cha.com/collections/taiwan-oolong-tea',
    'https://eco-cha.com/collections/green-tea',
    'https://eco-cha.com/collections/taiwan-black-tea'
   ];
  for (let url of urls) {
    let pageNum = 1;
    const page = await browser.newPage();
    await page.goto(url);

    //while looping through pages for url
    while (true) {      
      await page.waitForSelector('.product-thumbnail');
      let type = null;
      switch (true) {
        case url.includes('oolong'):
        type = 'oolong';
        break;
        case url.includes('white'):
        type = 'white';
        break;
        case url.includes('black'):
        type = 'black';
        break;
        case url.includes('green'):
        type = 'green';
        break;
        case url.includes('pu-erh'):
        type = 'pu-erh';
        break;
      }
      const teas = await page.$$eval('.product', (productElements, type) => {
        return productElements
          .map((productElement) => {
        const nameElement = productElement.querySelector('.product-card-details .title a');
        const priceElement = productElement.querySelector('.product-card-details .price .money');
        const name = nameElement ? nameElement.textContent.trim() : null;
        const link = nameElement ? nameElement.href : null;
        const price = priceElement ? priceElement.textContent.trim() : null;

        return { name, type, link, price };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('collection')); // Filter out products with "collection" in the title
      }, type);
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
}

module.exports = { scrapeInit};