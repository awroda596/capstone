//product details pages various vastly from site to site, map scrapers for each site
const descriptionScrapers = {
    'Red Blossom Tea Company': scrapeDescriptionRedBlossom,
    'Eco-Cha': scrapeDescriptionEcoCha
};

/*
const imageScrapers = {
    'Red Blossom Tea Company': scrapeImageRedBlossom,
    'Eco-Cha': scrapeImageRedBlossom,
};
*/
async function scrapeDescriptionRedBlossom(page) {
    return await page.$eval(
        '.page-body-content',
        el => Array.from(el.querySelectorAll('li.active p'))
            .map(p => p.textContent.trim())
            .filter(Boolean)
            .join('\n\n')
    );
}

async function scrapeDescriptionEcoCha(page) {
    try {
      const description = await page.$eval(
        'main#main-content li#tab2',
        el => Array.from(el.querySelectorAll('p'))
                  .map(p => p.textContent.trim())
                  .filter(Boolean)
                  .join('\n\n') || 'N/A'
      );
      return description;
    } catch (error) {
      console.warn(`⚠️ Failed to scrape description from tab2:`, error);
      return 'N/A'; //if can't find description, return N/A so it doesn't scrape info on subsequent scrapes. 
    }
  }
  


//check if a selector exists for a given site. 
async function checkSelector(page, selector) {
    if (!selector) return null;
    const exists = await page.$(selector);
    if (!exists) return null;
    return await page.$eval(selector, el => el.textContent.trim());
}



module.exports = {descriptionScrapers, checkSelector}; 
