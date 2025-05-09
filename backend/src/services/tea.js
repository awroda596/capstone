//handles tea related mongodb operations
const Tea = require('../models/tea');
const { chromium } = require('playwright');
const { sites } = require('../config/webscraping.js');
const { getTimestamp } = require('../utils/timestamp.js');
const { SecurityDetails } = require('puppeteer');

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
            type: tea.type,
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
      else {
        {
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
  return { errorCount, createCount, updateCount }; // Return the counts as an object
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
    else {
      {
        updateCount = 1
        //console.log(`[${getTimestamp()}] Updated tea: ${tea.name} from ${tea.vendor}`);
      }
    }
  } catch (error) {
    errorCount++;
    throw error; //throw error if there is an error

  }

  return { errorCount, createCount, updateCount }; // Return the counts as an object
}


//get teas based on query, type, and vendor; 
async function getTeas({ query, type, vendor, offset = 0, limit = 20 }) {
  const skip = parseInt(offset, 10);
  const lim = parseInt(limit, 10);

  const filter = {};

  if (query) {
    const regex = new RegExp(query, 'i');
    const stringFields = Object.entries(Tea.schema.paths)
      .filter(([key, path]) =>
        path.instance === 'String' && !key.startsWith('_')
      )
      .map(([key]) => ({ [key]: regex }));
    filter.$or = stringFields;
  }

  if (type) filter.type = type;
  if (vendor) filter.vendor = vendor;

  const results = await Tea.find(filter).skip(skip).limit(lim + 1);
  const hasMore = results.length > lim;

  return {
    results: hasMore ? results.slice(0, lim) : results,
    hasMore
  };
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

// set details for a tea.  details is an object with attributes gathered from getTeaInfo

async function updateTea(tea, details) {
  if (!details) {
    console.error(`[${getTimestamp()}] No details provided for tea ${tea._id}`);
    return null;
  }
  try {
    const updatedTea = await Tea.findByIdAndUpdate(
      tea._id, // Use the tea's _id for the update
      { $set: details },
      { new: true } // return the updated doc
    );

    if (!updatedTea) {
      console.warn(`Tea with ID ${tea._id} not found`);
      return null;
    }

    console.log(`[${getTimestamp()}] Updated tea ${tea._id} with details:`, details);

    return updatedTea;
  } catch (error) {
    console.error(`[${getTimestamp()}] Error updating tea ${tea._id}:`, error.message);
    console.error(`Error updating tea ${tea._id}:`, error);
    throw error;
  }
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


//parse through the structured query and find matching teas!
async function findTeas({ search, filters, offset = 0, limit = 20 }) {
 const query = { $and: [] };

  // Text search on name, description, flavorNotes
  if (search?.trim()) {
    const regex = new RegExp(search.trim(), "i");
    query.$and.push({
      $or: [
        { name: { $regex: regex } },
        { description: { $regex: regex } },
        { flavorNotes: { $regex: regex } }
      ]
    });
  }

  // Exact-match filters with $in
  const arrayFields = ['vendor', 'type', 'origin', 'style', 'harvest'];
  arrayFields.forEach(field => {
    if (filters[field]?.length) {
      query.$and.push({ [field]: { $in: filters[field] } });
    }
  });

  // Rating: treat as minimum rating
  if (typeof filters.rating === 'number') {
    query.$and.push({ rating: { $gte: filters.rating } });
  }

  // Price range
  if (filters.price?.min != null || filters.price?.max != null) {
    const priceQuery = {};
    if (typeof filters.price.min === 'number') {
      priceQuery.$gte = filters.price.min;
    }
    if (typeof filters.price.max === 'number') {
      priceQuery.$lte = filters.price.max;
    }
    query.$and.push({ price: priceQuery });
  }

  if (query.$and.length === 0) delete query.$and;

  const [results, total] = await Promise.all([
    Tea.find(query).skip(offset).limit(limit),
    Tea.countDocuments(query)
  ]);

  return {
    results,
    hasMore: offset + limit < total
  };
}

module.exports = { pushTeas, pushTea, getTeas, findTeas, updateTea, getUndescribedTeas, markLostTeas };