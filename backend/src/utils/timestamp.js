
getTimestamp = () => {
    const date = new Date();
    return date.toISOString().replace(/T/, ' ').replace(/\..+/, ''); //make human readable by replacing a few things
}

module.exports = {
    getTimestamp
};