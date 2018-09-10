var hebrew = require('./hebrew/strongs-hebrew-dictionary.js'),
	greek = require('./greek/strongs-greek-dictionary.js');

module.exports = Object.assign( {}, hebrew, greek );
