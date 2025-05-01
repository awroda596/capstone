
const mongoose = require('mongoose');
const { BrowserEvent } = require('puppeteer');

const teaSchema = new mongoose.Schema({
  name: { type: String, required: true },
  link: { type: String, required: true },
  type: { type: String, required: true },
  price: { type: String, default: 'N/A' },
  description: { type: String, default: null},
  flavorNotes: { type: String, default: null}, //flavor notes from vendor, if available
  tastingNotes: { type: String, default: null}, //tasting notes from vendor, if available
  
  userFlavorNotes: { type: String, default: null}, //may remove, user submitted flavor notes
  rating: { type: Number, default: null }, //out of 10
  numRatings: { type: Number, default: 0 }, //number of ratings
  vendor: { type: String, default: 'N/A' },
  reviews: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Review' }],

  // if easily available, origin country and region, otherwise just what is put in the website or leave blank
  origin: { 
    raw: { type: String, default: null }, 
    country: { type: String, default: null }, 
    region: { type: String, default: null } }, 

  style: { type: String, default: null }, //sub style of tea, such as faw or ripe for pu-erh teas or pheonix/dan cong for oolong teas
  images: [{ type: String, default: null }], //array of image urls for the tea, linked to the images on the tea's product page
  
  //parameters for brewing instructions if provided by vendor
  brewInstructions: { 
    brewText: { type: String, default: null }, //specific brewing instructions from the tea vendor, if available
    ratio: { type: String, default: null }, //tea to water ratio, if available
    teaWeight: { type: String, default: null }, //tea weight if ratio sis not available
    waterWeight: { type: String, default: null }, //water weight if ratio is not available
    steepTime: { type: String, default: null }, //steeptime, if available
  },
  harvest: { 
    year: { type: String, default: null }, //harvest year if available
    month: { type: String, default: null }, //harvest month if available
    season: { type: String, default: null }, //harvest season if available
    date: { type: String, default: null }, //harvest date if available
  },

  source: { type: String, default: null }, //source of the tea if available. 
},{ timestamps: true,   },);

const Tea = mongoose.model('Tea', teaSchema);

module.exports = Tea;
 