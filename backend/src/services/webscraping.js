const { chromium } = require('playwright');
const { sites } = require('../config/webscraping.js');
const { pushTeas } = require('./tea.js');



const teaTypes = [
  { key: 'oolong', value: 'oolong' },
  { key: 'white', value: 'white' },
  { key: 'black', value: 'black' },
  { key: 'green', value: 'green' },
  { key: ['puerh', 'pu-erh'], value: 'pu-erh' },
];

//gather new teas and update prices of existing teas
const scrapeTeas = async () => {
  const browser = await chromium.launch({ headless: true });
  let allTeas = [];
  for (siteInfo of sites) {
    const { site: siteName, urls, scrapeSelector, vendor: sVendor, typeSelector } = siteInfo;
    const { awaitSelector, productSelector, nameSelector, priceSelector, paginationSelector } = scrapeSelector;
    let siteTeas = [];
    for (let url of urls) {
      try {
        let pageNum = 1;
        const page = await browser.newPage();
        await page.goto(url);
        //while looping through pages for url
        while (true) {
          console.log(`Scraping ${siteName} page ${pageNum}...`);
          await page.waitForSelector(awaitSelector);
          console.log(`Waiting for ${awaitSelector}...`);
          let type = typeSelector(url);
          const context = { ...siteInfo, type };
          teas = await page.$$eval(
            productSelector,
            (productElements, { nameSelector, priceSelector, vendor, type }) => {
              return productElements.map((productElement) => {
                const nameElement = productElement.querySelector(nameSelector);
                const priceElement = productElement.querySelector(priceSelector);
                const name = nameElement ? nameElement.textContent.trim() : null;
                const link = nameElement ? nameElement.href : 'N/A';
                const price = priceElement ? priceElement.textContent.trim() : 'Sold Out';
                return { name, type, vendor, link, price };
              });
            },
            { nameSelector, priceSelector, vendor: sVendor, type } // Pass required data
          );
          siteTeas = siteTeas.concat(teas);
          // check for next page
          const nextPageLink = await page.$(paginationSelector);  // Check for the <a> inside <li class="next">
          if (nextPageLink) {
            //console.log('checking for next page');
            const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
            await page.goto(nextPageUrl);
            pageNum++;
            //console.log(`Navigating to page ${pageNum}...`);
            const currentUrl = await page.url();
            //console.log('Current page URL:', currentUrl);
            await page.waitForTimeout(2000); // Wait for the next page to load
          } else {
            //console.log('No more pages to scrape.');
            break;  // Exit While() loop
          }
        }
        await page.close(); // Close the current page after scraping
      } catch (error) {
        console.error(`Error scraping ${url}:`, error);
      }
    }
    allTeas = allTeas.concat(siteTeas);
  }
  for (let tea of allTeas) {
    console.log(`Scraped Tea:`, tea);
  }
  pushTeas(allTeas);
  //gather links then compare to existing teas to see to find dead links/sold out teas
  const links = allTeas.map(tea => tea.link);
  

}
//upsert teas
module.exports = {
  scrapeTeas
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
        console.log(`Scraped Tea:`, tea);
      }
      /
      // check for next page
      const nextPageLink = await page.$('.pagination li.next a');  // Check for the <a> inside <li class="next">
      if (nextPageLink) {
        //console.log('checking for next page');
        const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
        await page.goto(nextPageUrl);
        pageNum++;
        //console.log(`Navigating to page ${pageNum}...`);
        const currentUrl = await page.url();
        //console.log('Current page URL:', currentUrl);
        await page.waitForTimeout(2000); // Wait for the next page to load
      } else {
        //console.log('No more pages to scrape.');
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
  console.log('Scraped ', ecoTeas.length, ' from Eco-Cha');
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
      //  console.log(`Scraped Tea:`, tea);
      //}

      rbTeas = rbTeas.concat(teas);

      // check for next page
      const nextPageLink = await page.$('.pagination li.next a');  // Check for the <a> inside <li class="next">
      if (nextPageLink) {
        //console.log('checking for next page');
        const nextPageUrl = await page.evaluate((link) => link.href, nextPageLink);  // Get the href of the Next link
        await page.goto(nextPageUrl);
        pageNum++;
        //console.log(`Navigating to page ${pageNum}...`);
        const currentUrl = await page.url();
        //console.log('Current page URL:', currentUrl);
        await page.waitForTimeout(2000); // Wait for the next page to load
      } else {
        //console.log('No more pages to scrape.');
        break;  // Exit While() loop
      }
      
    }
    await page.close(); // Close the current page after scraping
    }
    catch (error) {
      console.error(`Error scraping ${url}:`, error);
      failedUrls.push(url);
    }
  }
  
  await browser.close();
  console.log('Scraped ', rbTeas.length, ' from Red Blossom Tea Company');
  return rbTeas;
}

*/








/*old scraping that scraped from list and individual pages */
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

