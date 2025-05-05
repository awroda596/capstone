//handles any webscraping logic. 
const { chromium, selectors } = require('playwright');
const { sites } = require('../config/webscraping.js');
const { pushTeas, markLostTeas, getUndescribedTeas, updateTea } = require('./tea.js');
const { getTimestamp } = require('../utils/timestamp.js');
const { checkSelector, descriptionScrapers } = require('../utils/scrapeHelper.js');
const Tea = require('../models/tea');

const teaTypes = [
  { key: 'oolong', value: 'Oolong' },
  { key: 'white', value: 'White' },
  { key: 'black', value: 'Black' },
  { key: 'green', value: 'Green' },
  { key: ['puerh', 'pu-erh'], value: 'Pu\'erh' },
];

//gather new teas and update prices of existing teas
const scrapeTeas = async () => {
  let allTeas = []; // Initialize an array to store all teas

  const browser = await chromium.launch({ headless: true });
  let errorCount = 0;
  let createCount = 0;
  let updateCount = 0;
  for (siteInfo of sites) {
    let { urls, scrapeSelector, vendor: sVendor, typeSelector } = siteInfo;
    let { awaitSelector, productSelector, nameSelector, priceSelector, paginationSelector } = scrapeSelector;
    let siteTeas = []; //store teas per site
    for (let url of urls) {
      try {
        let pageNum = 1;
        let page = await browser.newPage();
        let response = await page.goto(url);
        if (!response || !response.ok()) {
          throw new Error(`[${getTimestamp()}] Failed to load ${url}: ${response.status()}`);
        }
        //while looping through pages for url
        while (true) {
          try {
            console.log(`[${getTimestamp()}] Scraping ${url} page ${pageNum}...`);
            await page.waitForSelector(awaitSelector);
            const type = typeSelector(url);
            const teas = await page.$$eval(productSelector, (productElements, { nameSelector, priceSelector, sVendor, teaType }) => {
              return productElements.map((productElement) => {
                const nameElement = productElement.querySelector(nameSelector);
                const priceElement = productElement.querySelector(priceSelector);
                const name = nameElement ? nameElement.textContent.trim() : null;
                const link = nameElement ? nameElement.href : 'N/A';
                let price = priceElement ? priceElement.textContent.trim() : 'Sold Out';
                const vendor = sVendor;
                if (price.toLowerCase().startsWith('us$')) {
                  price = price.slice(2);
                }
                const isScraped = true;
                return { name, type: teaType, vendor, link, price, isScraped };
              }).filter(tea => tea.name && !/collection|sample|flight|club/i.test(tea.name));
            }, { nameSelector, priceSelector, sVendor, teaType: type });
            
            
            pushResults = await pushTeas(teas); //push teas to db
            errorCount += pushResults.errorCount;
            createCount += pushResults.createCount;
            updateCount += pushResults.updateCount;
            siteTeas = siteTeas.concat(teas); // Add scraped teas to the siteTeas array
            // check for next page
            const nextPageLink = await page.$(paginationSelector);  //
            if (nextPageLink) {
              //console.log('[${getTimestamp()}] checking for next page');
              const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);
              await page.goto(nextPageUrl);
              pageNum++;
              //console.log(`[${getTimestamp()}] Navigating to page ${pageNum}...`);
              const currentUrl = await page.url();
              //console.log('[${getTimestamp()}] Current page URL:', currentUrl);
              await page.waitForTimeout(2000);
            } else {
              //console.log('[${getTimestamp()}] No more pages to scrape.');
              break;
            }
          } catch (error) {
            console.warn(`[${getTimestamp()}] Error scraping ${url} on page ${pageNum}:`);
            throw error;
          }
        }
        await page.close(); // Close the current page after scraping
      } catch (error) { //if an url or page can't be scraped, try the next url
        console.error(`[${getTimestamp()}] Error scraping ${url}:`, error);
        continue;
      }
    }
    allTeas = allTeas.concat(siteTeas); // Add site teas to the allTeas array
  }
  console.log(`[${getTimestamp()}] Scraping completed. Scraped ${allTeas.length} teas from ${sites.length} sites.`);
  console.log(`[${getTimestamp()}] Scraped ${createCount} new teas and updated ${updateCount} existing teas. Failed to upsert ${errorCount} teas.`);


  try {
    await markLostTeas(allTeas); //update lost teas in db
    let undescribed = await getUndescribedTeas(); //get teas that need descriptions
    console.log(`[${getTimestamp()}]  Found missing details for ${undescribed.length} teas,.`);
    await getTeaInfo(undescribed, browser); //scrape descriptions for teas that need them
    console.log(`[${getTimestamp()}] completed scraping descriptions for ${undescribed.length} teas.`);
  } catch (error) {
    // if can't get undescribed teas, skip filling them. 
    console.error(`[${getTimestamp()}] error in getUndescribed Teas:`, error);
  }
  console.log(`[${getTimestamp()}] Scraping completed. Scraped ${allTeas.length} teas from ${sites.length} sites.`);


}

//scrape for tea descriptions and more
// just descriptions for now, will expand to include images, origin, etc. 
const getTeaInfo = async (teas, browser) => {
  errorCount = 0;
  createCount = 0;
  updateCount = 0;
  for (let tea of teas) {
    try {
      let page = await browser.newPage();
      //scraping stuff
      let siteInfo = sites.find(site => tea.vendor.toLowerCase().includes(site.vendor.toLowerCase()));
      if (!siteInfo) {
        throw new Error(`[${getTimestamp()}] No site info found for ${tea.vendor}`);
      }
      let selectors = siteInfo.scrapeSelector; //get the selectors for the site
      let url = tea.link;
      console.log(`[${getTimestamp()}] Scraping details for ${tea.name} from ${url}...`);
      let response = await page.goto(url);
      if (!response || !response.ok()) {
        throw new Error(`[${getTimestamp()}] Failed to load ${url}: ${response.status()}`);
      }
      let result = await page.waitForSelector(selectors.detailSelector, { timeout: 10000 });

      if (!result) {
        throw new Error(`[${getTimestamp()}] Failed to load details for ${tea.name}`);
      }

      //descscraper uses the appropriate description scraper for the teas vendor
      const descScraper = descriptionScrapers[tea.vendor];
      if (!descScraper) {
        throw new Error(`[${getTimestamp()}] No description scraper found for ${tea.name} from ${tea.vendor}!`);
      }

      //now push the tea to the db
      try {
        const details = await descScraper(page); //scrape the description
        result = await updateTea(tea, details); //push the tea to the db
      }

      catch (error) {
        console.error(`[${getTimestamp()}] Error pushing tea ${tea.name}:`, error);
        errorCount++;
        continue; // Skip to the next tea if there's an error
      }
      page.close();
      // catch errors scraping a tea info
    } catch (error) {
      console.error(error);
      errorCount++;
      continue; // Skip this tea if an error occurs
    }

  }
  console.log(`[${getTimestamp()}] Info scraping completed. updated ${updateCount} teas and failed to update ${errorCount} teas.`);
}



//upsert teas
module.exports = {
  scrapeTeas,
  getTeaInfo,

};
/*

async function ecoCha() {
  const browser = await chromium.launch({ headless: true });
  const urls = [
    'https://eco-cha.com/collections/taiwan-oolong-tea',
    'https://eco-cha.com/collections/green-tea',
    'https://eco-cha.com/collections/taiwan-black-tea'
  ];
  let ecoTeas = [];
  for (let url of urls) {
    let pageNum = 1;
    const page = await browser.newPage();
    await page.goto(url);
    //while looping through pages for url

    while (true) {
      await page.waitForSelector('main#main-content .collection-page__list');
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
      const teas = await page.$$eval('main#main-content .collection-page__content .collection-page__list .product-thumbnail', (productElements, type) => {
        return productElements
          .map((productElement) => {
            const nameElement = productElement.querySelector('.product-thumbnail__title');
            const priceElement = productElement.querySelector('.product-thumbnail__price .money');

            const name = nameElement ? nameElement.textContent.trim() : null;
            const link = nameElement ? nameElement.href : null;
            const price = priceElement ? priceElement.textContent.trim() : null;
            const vendor = 'Eco-Cha';
            return { name, type, vendor,link, price };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('Sampler')); // Filter out products with "collection" in the title
      }, type);
      ecoTeas = ecoTeas.concat(teas);
      /*
      for (let tea of teas) {
        console.log(`[${getTimestamp()}] Scraped Tea:`, tea);
      }
      /
      // check for next page
      const nextPageLink = await page.$('.pagination li.next a');  // Check for the <a> inside <li class="next">
      if (nextPageLink) {
        //console.log('[${getTimestamp()}] checking for next page');
        const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
        await page.goto(nextPageUrl);
        pageNum++;
        //console.log(`[${getTimestamp()}] Navigating to page ${pageNum}...`);
        const currentUrl = await page.url();
        //console.log('[${getTimestamp()}] Current page URL:', currentUrl);
        await page.waitForTimeout(2000); // Wait for the next page to load
      } else {
        //console.log('[${getTimestamp()}] No more pages to scrape.');
        break;  // Exit While() loop
      }
    }
    await page.close(); // Close the current page after scraping
  }
  // Filter out duplicates based on the tea name and link
  ecoTeas = ecoTeas.filter((tea, index, self) =>
    index === self.findIndex(t => t.name === tea.name && t.link === tea.link)
  );
  await browser.close();
  console.log('[${getTimestamp()}] Scraped ', ecoTeas.length, ' from Eco-Cha');
  return ecoTeas;
}
async function redblossomtea() {
  const browser = await chromium.launch({ headless: true });
  const urls = [
    'https://redblossomtea.com/collections/oolong',
    'https://redblossomtea.com/collections/white',
    'https://redblossomtea.com/collections/black',
    'https://redblossomtea.com/collections/pu-erh',
    'https://redblossomtea.com/collections/green',
  ];
  let rbTeas = [];
  for (let url of urls) {
    try{

    
    let pageNum = 1;
    const page = await browser.newPage();

    await page.goto(url);
    
    //while looping through pages for url

    while (true) {
      await page.waitForSelector('.product');
      let type = null;
      switch (url) {
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
            const vendor = 'Red Blossom Tea Company';
            return { name, type, vendor, link, price };
          })
          .filter(tea => tea.name && !tea.name.toLowerCase().includes('collection')); // Filter out products with "collection" in the title
      }, type);

      //debug show scraped teas
      //for (let tea of teas) {
      //  console.log(`[${getTimestamp()}] Scraped Tea:`, tea);
      //}

      rbTeas = rbTeas.concat(teas);

      // check for next page
      const nextPageLink = await page.$('.pagination li.next a');  // Check for the <a> inside <li class="next">
      if (nextPageLink) {
        //console.log('[${getTimestamp()}] checking for next page');
        const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
        await page.goto(nextPageUrl);
        pageNum++;
        //console.log(`[${getTimestamp()}] Navigating to page ${pageNum}...`);
        const currentUrl = await page.url();
        //console.log('[${getTimestamp()}] Current page URL:', currentUrl);
        await page.waitForTimeout(2000); // Wait for the next page to load
      } else {
        //console.log('[${getTimestamp()}] No more pages to scrape.');
        break;  // Exit While() loop
      }
      
    }
    await page.close(); // Close the current page after scraping
    }
    catch (error) {
      console.error(`[${getTimestamp()}] Error scraping ${url}:`, error);
      failedUrls.push(url);
    }
  }
  
  await browser.close();
  console.log('[${getTimestamp()}] Scraped ', rbTeas.length, ' from Red Blossom Tea Company');
  return rbTeas;
}

*/








/*old scraping that scraped from list and individual pages */
/*
for (let tea of teas) {
  if (tea.link) {
    const productPage = await browser.newPage();
    await productPage.goto(tea.link);

    console.log(`[${getTimestamp()}] Navi      await page.waitForSelector('.product');
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
      console.log(`[${getTimestamp()}] Scraped Tea:`, tea);

    } catch (error) {
      console.error(`[${getTimestamp()}] Error scraping product ${tea.link}:`, error);
    }

    await productPage.close(); 

  }//if tea has link
}

 
*/

