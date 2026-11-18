// Exposes the CRM snapshot endpoint. Keep a single initializeApp() call,
// which lives in crmSnapshot.js.
const { crmSnapshot } = require('./crmSnapshot');
exports.crmSnapshot = crmSnapshot;