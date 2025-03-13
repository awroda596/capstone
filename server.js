// Import the http module
/*
const http = require('http');

// Create a server
const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Welcome to the Node.js Tutorial');
});

// Listen on port 3000
server.listen(3000, () => {
    console.log('Server is running on http://localhost:3000');
});
*/
// app.js

const puppeteer = require('puppeteer');

async function webScraper() {
    const browser = await puppeteer.launch({})
    const page = await browser.newPage()
    await page.goto(
'https://www.geeksforgeeks.org/explain-the-mechanism-of-event-loop-in-node-js/')
    let element = await page.waitForSelector("h1"); 
    let text = await page.evaluate(
        element => element.textContent, element)
    console.log(text)
    browser.close()
};

webScraper();