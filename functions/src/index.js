const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Importar funciones
const { identifyPlant } = require('./plant-identification');
const { sendWateringReminders, checkUserPlants } = require('./watering-reminders');

// Exportar funciones
module.exports = {
  identifyPlant,
  sendWateringReminders,
  checkUserPlants,
};
