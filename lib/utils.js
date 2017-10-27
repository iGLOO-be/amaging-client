
const _ = require('lodash');
const moment = require('moment');

module.exports = {
  parseJSON(str) {
    try {
      return JSON.parse(str);
    } catch (e) {
      return null;
    }
  }
};
