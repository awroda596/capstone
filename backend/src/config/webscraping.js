// webscraping constants and configurations
// gives the correct CSS selectors for each site as well as the type of tea for each site

const { ServerDescription } = require("mongodb");


// types


const generalTypeSelector = (url) => {
    if (url.includes('oolong')) return 'oolong';
    if (url.includes('white')) return 'white';
    if (url.includes('black')) return 'black';
    if (url.includes('green')) return 'green';
    if (url.includes('pu-erh')) return 'pu-erh';
    return 'other';
};

const redBlossomTypeSelector = (url) => {
    if (url.includes('oolong')) return 'oolong';
    if (url.includes('white')) return 'white';
    if (url.includes('black')) return 'black';
    if (url.includes('green')) return 'green';
    if (url.includes('pu-erh')) return 'pu-erh';
    return 'other';
};

const ecoChaTypeSelector = (url) => {
    if (url.includes('oolong')) return 'oolong';
    if (url.includes('green')) return 'green';
    if (url.includes('black')) return 'black';
    return 'other';
};



//scraping selectors
const redBlossomTeaScrapeSelectors = {
    awaitSelector: '.page-body-content',
    productSelector: '.page-body-content .product-list.row-of-4 li',
    nameSelector: '.product-card-details h2.title a',
    priceSelector: '.product-card-details .price .money',
    paginationSelector: '.pagination li.next a',
    detailSelector: '.page-body-content', //product page details 
    detailDescriptionSelector: '.product-description',
    detailFlavorNotesSelector: '.product-flavor-notes',
    detailImagesSelector: '.product-images img',
    
};



const ecoChaScrapeSelectors = {
    awaitSelector: 'main#main-content .collection-page__list',
    productSelector: 'main#main-content .collection-page__content .collection-page__list .product-thumbnail',
    nameSelector: '.product-thumbnail__title',
    priceSelector: '.product-thumbnail__price .money',
    paginationSelector: '.pagination li.next a',
    detailSelector: '.tabs-content', //product page details 
    detailDescriptionSelector: '.product-description',
    detailFlavorNotesSelector: '.product-flavor-notes',
    detailImagesSelector: '.product-images img',
};


const redBlossomTeaDetailSelectors = {


};
//sites  set urls, scraping, and types for each website
const sites = [
    {
        site: 'Red Blossom Tea Company',
        urls: [
            'https://redblossomtea.com/collections/oolong',
            'https://redblossomtea.com/collections/white',
            'https://redblossomtea.com/collections/black',
            'https://redblossomtea.com/collections/pu-erh',
            'https://redblossomtea.com/collections/green',
        ],
        scrapeSelector: redBlossomTeaScrapeSelectors,
        vendor: 'Red Blossom Tea Company',
        typeSelector: redBlossomTypeSelector,
    },
    {
        site: 'Eco-Cha',
        urls: [
            'https://eco-cha.com/collections/taiwan-oolong-tea',
            'https://eco-cha.com/collections/green-tea',
            'https://eco-cha.com/collections/taiwan-black-tea',
        ],
        scrapeSelector: ecoChaScrapeSelectors,
        vendor: 'Eco-Cha',
        typeSelector: ecoChaTypeSelector,
    }
  ];

module.exports = {
    sites
};