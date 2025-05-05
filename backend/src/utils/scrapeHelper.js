const Tea = require("../models/tea");

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
  try {
    return await page.$eval('.tabs-content', (activeEl) => {
      const details = {};

      const firstLi = activeEl.querySelector('li');
      if (firstLi) {
        const paragraphNodes = Array.from(firstLi.children).filter(
          el => el.tagName === 'P'
        );

        const description = paragraphNodes
          .map(p => p.textContent.trim())
          .join('\n\n');

        if (description) {
          details.description = description;
        }
      }

      //get all the stuff under tea-description class
      const rows = activeEl.querySelectorAll('tr.tea-description');
      rows.forEach(row => {
        const tds = row.querySelectorAll('td');
        tds.forEach(td => {
          const p = td.querySelector('p');
          if (!p) return;
          const spans = p.querySelectorAll('span');
          if (spans.length < 2) return;
          const labelEl = spans[0].querySelector('em');
          const label = labelEl?.textContent?.trim().toLowerCase() || '';
          const value = spans[1].textContent?.trim();
          if (!label || !value) return;
          if (label.includes('origin')) {
            details.origin = value;
          } else if (label.includes('craft')) {
            details.style = value;
          } else if (label.includes('flavor')) {
            details.flavorNotes = value;
          }
        });
      });
      return details;
    });
  } catch (error) {
    // rbtc has 2 styles of pages, this is for the ones with more basic structure: 
    try {
      return await page.$eval('.rte', el => {
        const details = {};
        const paragraphs = Array.from(el.querySelectorAll('p'));
        const text = paragraphs.map(p => p.textContent.trim()).join('\n\n');
        if (text) {
          details.description = text;
        }
        return details;
      });
    } catch (fallbackError) {
      // Final fallback: return minimal details
      return { description: 'N/A' };
    }
  }
}

async function scrapeDescriptionEcoCha(page) {
  return await page.$eval('.tabs-content', el => {
    const details = {};

    // tab1 = li.active
    const tab1 = el.querySelector('li#tab1');
    if (tab1) {
      const ps = tab1.querySelectorAll('p');

      ps.forEach(p => {
        const strong = p.querySelector('strong');
        if (!strong) return;
        const label = strong.textContent.trim().toLowerCase().replace(':', '');
        const text = p.textContent.replace(strong.textContent, '').trim();
        if (label === 'flavor') {
          details.flavorNotes = text;
        }

        if (label === 'harvest') {
          details.origin = text;
        }
      });
    }

    // tab2 = li#tab2
    const tab2 = el.querySelector('li#tab2');
    if (tab2) {
      const desc = Array.from(tab2.querySelectorAll('p'))
        .map(p => p.textContent.trim())
        .filter(Boolean)
        .join('\n\n');
      if (desc) {
        details.description = desc;
      }
    }

    return details;
  });
}


//check if a selector exists for a given site, not used currently.  
async function checkSelector(page, selector) {
  if (!selector) return null;
  const exists = await page.$(selector);
  if (!exists) return null;
  return await page.$eval(selector, el => el.textContent.trim());
}



module.exports = { descriptionScrapers, checkSelector }; 
