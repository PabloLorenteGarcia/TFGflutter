const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Importar funciones
const { identifyPlant } = require('./plant-identification');

// Exportar funciones
module.exports = {
  identifyPlant,
};
