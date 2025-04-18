const Tea = require('../models/tea.model');

async function pushTeas(teas) {
  try {
    for (let tea of teas) {
    await Tea.findOneAndUpdate(
      { name: tea.name, vendor: tea.vendor }, // Match by name and vendor
        { 
          name: tea.name,
          link: tea.link,
          vendor: tea.vendor,
          price: tea.price 
        }, // Update fields
        { upsert: true, new: true } // Create if not exists, return the new document
      );
    }
  } catch (error) {
    console.error("Error in pushTeas:", error);
    throw error; 
  }
  console.log('upserted ',teas.length, ' teas to MongoDB');
}

async function getTeas() {
  try {
    const teas = await Tea.find({});
    return teas;
  } catch (error) {
    console.error("Error in getTeaas:", error);
    throw error; 
  }
}

module.exports = { pushTeas, getTeas };