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
            if(paginationSelector == 'scroll'){
              scrollProducts(page, productSelector); 
            }
            const type = typeSelector(url);
            //prouduct selector should select the top level that contains every tea on page as close as possible
            // page function (named productElement and destructure args)
            // return it as a mapped object
            const teas = await page.$$eval(productSelector, (productElements, { nameSelector, priceSelector, sVendor, teaType }) => {
              return productElements.map((productElement) => {
                const nameElement = productElement.querySelector(nameSelector);
                const priceElement = productElement.querySelector(priceSelector);
                const anchor = productElement.querySelector('a'); 
                const name = nameElement ? nameElement.textContent.trim() : null;
                const link = anchor?.href ?? 'N/A';
                let price = priceElement ? priceElement.textContent.trim() : 'Sold Out';
                const vendor = sVendor;
                if (price.toLowerCase().startsWith('us$')) {
                  price = price.slice(2);
                }
                const isScraped = true;
                return { name, type: teaType, vendor, link, price, isScraped };
              }).filter(tea => tea.name && !/collection|sample|flight|club/i.test(tea.name)); //keep it to single teas for simplicity sake
            }, { nameSelector, priceSelector, sVendor, teaType: type });
            
            
            pushResults = await pushTeas(teas); //push teas to db
            errorCount += pushResults.errorCount;
            createCount += pushResults.createCount;
            updateCount += pushResults.updateCount;
            siteTeas = siteTeas.concat(teas); // Add scraped teas to the siteTeas array
            // check for next page if not of type scroll
            if(paginationSelector != 'scroll'){
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

//handle pages that scroll instead of paginate.  count items stop scrolling if no more load.  easy 
async function scrollProducts(page, productSelector, delay = 1000, max = 30) {
  let previousCount = 0;
  for (let i = 0; i < max; i++) {
    const items = await page.$$(productSelector);
    const currentCount = items.length;

    if (currentCount > previousCount) {
      previousCount = currentCount;
      await page.evaluate(() => window.scrollBy(0, window.innerHeight));
      await page.waitForTimeout(delay);
    } else {
      break; // no new items loaded
    }
  }
}

//upsert teas
module.exports = {
  scrapeTeas,
  getTeaInfo,

};

