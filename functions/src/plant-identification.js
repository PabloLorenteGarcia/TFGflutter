const functions = require('firebase-functions');
const axios = require('axios');
const FormData = require('form-data');

const PLANTNET_API_KEY = process.env.PLANTNET_API_KEY || '2b10bT6FVImRsZ7G6ppf8p72O';
const PLANTNET_BASE_URL = 'https://my-api.plantnet.org/v2';

exports.identifyPlant = functions.https.onCall(async (data, context) => {
  try {
    // Verificar autenticación
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'El usuario debe estar autenticado');
    }

    const { images, organs, project = 'all' } = data;

    if (!images || !Array.isArray(images) || images.length === 0) {
      throw new functions.https.HttpsError('invalid-argument', 'Se requieren imágenes');
    }

    if (!organs || !Array.isArray(organs) || organs.length !== images.length) {
      throw new functions.https.HttpsError('invalid-argument', 'El número de órganos debe coincidir con el de imágenes');
    }

    if (images.length > 5) {
      throw new functions.https.HttpsError('invalid-argument', 'Máximo 5 imágenes permitidas');
    }

    const form = new FormData();

    // Agregar imágenes (base64 convertidas a buffers)
    for (let i = 0; i < images.length; i++) {
      const imageBase64 = images[i];
      const buffer = Buffer.from(imageBase64, 'base64');
      form.append('images', buffer, `image_${i}.jpg`);
      form.append('organs', organs[i]);
    }

    const url = `${PLANTNET_BASE_URL}/identify/${project}?api-key=${PLANTNET_API_KEY}`;

    const response = await axios.post(url, form, {
      headers: form.getHeaders(),
      timeout: 30000,
    });

    return {
      success: true,
      data: response.data,
    };
  } catch (error) {
    console.error('Error en identificación de planta:', error.message);
    throw new functions.https.HttpsError('internal', 
      `Error: ${error.response?.status || 'unknown'} - ${error.response?.data?.message || error.message}`
    );
  }
});
