//handles tea related mongodb operations
const Tea = require('../models/tea');
const { chromium } = require('playwright');
const { sites } = require('../config/webscraping.js');
const { getTimestamp } = require('../utils/timestamp.js');

async function pushTeas(teas) {
  try {
    for (let tea of teas) { //iterate all teas scraped

      await Tea.findOneAndUpdate(
        { name: tea.name, vendor: tea.vendor }, //update by name and vendor
        {
          $set: { //update the tea document
            name: tea.name,
            link: tea.link,
            vendor: tea.vendor,
            price: tea.price,
            isScraped: true,
          }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
    }

    console.log(`[${getTimestamp()}] Upserted ${teas.length} teas to MongoDB`);
  } catch (error) {
    console.error(`[${getTimestamp()}] Error in pushTeas:`, error);

    throw error;
  }
}

//push an array of teas to the database
async function pushTeas(teas) {
  let errorCount = 0; // Initialize error count
  let createCount = 0; // Initialize create count
  let updateCount = 0; // Initialize update count
  for (let tea of teas) { //iterate all teas scraped
    try {
      let foundTea = await Tea.findOneAndUpdate(
        { name: tea.name, vendor: tea.vendor }, //update by name and vendor
        {
          $set: { //update the tea document
            name: tea.name,
            link: tea.link,
            vendor: tea.vendor,
            price: tea.price,
            isScraped: true,
          }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
      if (foundTea.createdAt.getTime() === foundTea.updatedAt.getTime()) {
        createCount++;
        //console.log(`[${getTimestamp()}] Created new tea: ${tea.name} from ${tea.vendor}`);
      }
      else { {
        updateCount++;
        //console.log(`[${getTimestamp()}] Updated tea: ${tea.name} from ${tea.vendor}`);
      }
      } 
    } catch (error) {
      errorCount++;
      console.error(`[${getTimestamp()}] Error pushing ${tea.name}:`, error);
      continue; 
    }
    
  }
  return {errorCount, createCount, updateCount}; // Return the counts as an object
}

//push a single tea to the database
async function pushTea(tea) {
  let errorCount = 0; // Initialize error count
  let createCount = 0; // Initialize create count
  let updateCount = 0; // Initialize update count

    try {
      let foundTea = await Tea.findOneAndUpdate(
        { name: tea.name, vendor: tea.vendor }, //update by name and vendor
        {
          $set: { //update the tea document
            name: tea.name,
            link: tea.link,
            vendor: tea.vendor,
            price: tea.price,
            isScraped: true,
          }
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );
      if (!foundTea) {
        const error = new Error(`Tea not found: ${tea.name} from ${tea.vendor}`);
        throw error; //throw error if tea is not found
      }
      if (foundTea.createdAt.getTime() === foundTea.updatedAt.getTime()) {
        createCount = 1
        //console.log(`[${getTimestamp()}] Created new tea: ${tea.name} from ${tea.vendor}`);
      }
      else { {
        updateCount = 1
        //console.log(`[${getTimestamp()}] Updated tea: ${tea.name} from ${tea.vendor}`);
      }
      } 
    } catch (error) {
      errorCount++;
      throw error; //throw error if there is an error

    }

    return {errorCount, createCount, updateCount}; // Return the counts as an object
}




async function getTeas() {
  try {
    const teas = await Tea.find({});
    return teas;
  } catch (error) {
    console.error(`[${getTimestamp()}] Error in getTeas:`, error);
    throw error;
  }
}

//find teas that have not been scraped for descriptions yet. 
async function getUndescribedTeas() {
  console.log(`[${getTimestamp()}] finding scraped teas without info...`);
  let uTeas = [];

  try {
    uTeas = await Tea.find({ description: null, isScraped: true }); 
    console.log(`[${getTimestamp()}] found ${uTeas.length} teas without descriptions`);
  } catch (error) {
    console.error(`[${getTimestamp()}] error finding undescribed teas:`, error.message);
    throw error;
  }

  return uTeas;
}

// function to upsert tea details to the database: right now just description but details will hold all the things
async function pushTeaDetails(tea, details)
{
  let result = await Tea.findOneAndUpdate(
    { name: tea.name, vendor: tea.vendor }, //update by name and vendor
    {
      $set: { //update the tea document
        name: tea.name,
        link: tea.link,
        description: details.description || 'N/A',
      }
    },
  );

}


const markLostTeas = async (teas) => {
  const scrapedTeas = teas.map(tea => ({
    name: tea.name,
    vendor: tea.vendor
  }));

  try {
    console.log(`[${getTimestamp()}] finding missing teas...`);
    const result = await Tea.find({
      isScraped: true,  // Ensure isScraped is true
      $nor: scrapedTeas.map(tea => ({
        name: tea.name,
        vendor: tea.vendor
      }))  //using vendor + name as a unique identifier, exclude matching teas from the db
    })
    console.log(`[${getTimestamp()}] found ${result.length} missing teas`);
    for (let tea of result) {
      await Tea.findOneAndUpdate(
        { name: tea.name, vendor: tea.vendor }, //update by name and vendor
        {
          $set: { //update the tea document
            price: 'Sold Out',
            link: 'N/A',
          }
        },
        { new: true } // Return the updated document
      );
    }
    console.log(`[${getTimestamp()}] Updated ${result.length} lost teas.`);
  } catch (err) {
    console.error('Error fetching teas:', err);
    return null;
  }
}



module.exports = { pushTeas, pushTea, getTeas, pushTeaDetails,  getUndescribedTeas, markLostTeas };