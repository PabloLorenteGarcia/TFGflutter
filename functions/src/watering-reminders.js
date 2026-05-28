const functions = require('firebase-functions');
const admin = require('firebase-admin');

/**
 * Función scheduled que se ejecuta cada hora para enviar notificaciones de riego
 * Se ejecuta automáticamente cada hora para verificar cuáles plantas necesitan riego
 */
exports.sendWateringReminders = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    console.log('🌿 Iniciando verificación de plantas para riego...');

    try {
      const db = admin.firestore();
      const messaging = admin.messaging();

      // Obtener todos los usuarios
      const usersSnapshot = await db.collection('usuarios').get();
      console.log(`📊 Total de usuarios: ${usersSnapshot.size}`);

      let totalNotificationsSent = 0;
      const now = new Date();

      // Iterar sobre cada usuario
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        // Obtener token FCM del usuario si existe
        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
          console.log(`⚠️ Usuario ${userId} no tiene FCM token`);
          continue;
        }

        // Obtener todas las plantas del usuario
        const plantsSnapshot = await db
          .collection('usuarios')
          .doc(userId)
          .collection('plantas')
          .where('notificationsEnabled', '==', true)
          .get();

        console.log(`🌱 Usuario ${userId} tiene ${plantsSnapshot.size} plantas con notificaciones habilitadas`);

        // Verificar cada planta
        for (const plantDoc of plantsSnapshot.docs) {
          const plant = plantDoc.data();
          const plantId = plantDoc.id;

          // Verificar si la planta necesita riego
          if (plant.nextWatering) {
            const nextWateringTime = new Date(plant.nextWatering);

            if (now >= nextWateringTime) {
              // La planta necesita riego - enviar notificación
              const message = {
                notification: {
                  title: `💧 Hora de regar ${plant.name}`,
                  body: `Tu ${plant.name} necesita agua. Cantidad: ${plant.wateringAmountLiters}L`,
                },
                data: {
                  plantId: plantId,
                  plantName: plant.name,
                  action: 'water_plant',
                },
                token: fcmToken,
              };

              try {
                const response = await messaging.send(message);
                console.log(`✅ Notificación enviada a ${userId} para ${plant.name}: ${response}`);
                totalNotificationsSent++;

                // Registrar que se envió la notificación
                await db
                  .collection('usuarios')
                  .doc(userId)
                  .collection('plantas')
                  .doc(plantId)
                  .update({
                    lastNotificationSent: admin.firestore.FieldValue.serverTimestamp(),
                  });
              } catch (error) {
                console.error(`❌ Error al enviar notificación a ${userId}: ${error}`);
              }
            }
          }
        }
      }

      console.log(`✅ Verificación completada. Total de notificaciones enviadas: ${totalNotificationsSent}`);
      return null;
    } catch (error) {
      console.error(`❌ Error en sendWateringReminders: ${error}`);
      throw error;
    }
  });

/**
 * Función manual para verificar riego de un usuario específico
 * Útil para debugging y pruebas
 */
exports.checkUserPlants = functions.https.onCall(async (data, context) => {
  // Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }

  const userId = context.auth.uid;
  console.log(`🔍 Verificando plantas del usuario: ${userId}`);

  try {
    const db = admin.firestore();

    // Obtener todas las plantas del usuario con notificaciones habilitadas
    const plantsSnapshot = await db
      .collection('usuarios')
      .doc(userId)
      .collection('plantas')
      .where('notificationsEnabled', '==', true)
      .get();

    const now = new Date();
    let plantsNeedingWater = [];
    let notificationsSent = 0;

    // Verificar cada planta
    for (const plantDoc of plantsSnapshot.docs) {
      const plant = plantDoc.data();
      const plantId = plantDoc.id;

      if (plant.nextWatering) {
        const nextWateringTime = new Date(plant.nextWatering);

        if (now >= nextWateringTime) {
          plantsNeedingWater.push({
            id: plantId,
            name: plant.name,
            nextWatering: nextWateringTime,
            wateringAmount: plant.wateringAmountLiters,
          });

          notificationsSent++;
        }
      }
    }

    console.log(`✅ Plantas que necesitan riego: ${plantsNeedingWater.length}`);

    return {
      success: true,
      message: `Se encontraron ${plantsNeedingWater.length} plantas que necesitan riego`,
      plants: plantsNeedingWater,
      totalPlants: plantsSnapshot.size,
      notificationsSent: notificationsSent,
    };
  } catch (error) {
    console.error(`❌ Error en checkUserPlants: ${error}`);
    throw new functions.https.HttpsError('internal', `Error: ${error.message}`);
  }
});
