const admin = require("firebase-admin");
const serviceAccount = require("./service-account.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

async function sendNotificationIfOnline(uid, title, body, data = {}) {
  try {
    const userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      console.log(`❌ Utilisateur ${uid} introuvable`);
      return;
    }

    const userData = userDoc.data();

    // devices peut être un tableau ou un objet (map)
    let devices = userData.devices || [];

    if (!Array.isArray(devices)) {
      // Si c’est un objet, convertis-le en tableau des valeurs
      devices = Object.keys(devices).map(key => devices[key]);
    }

    if (!Array.isArray(devices)) {
      console.log(`❌ devices n'est pas un tableau après conversion, notification annulée.`);
      return;
    }

    // Filtrer les devices en ligne avec token valide
    const onlineTokens = devices
      .filter(device => device.isOnline && device.fcmToken)
      .map(device => device.fcmToken);

    if (onlineTokens.length === 0) {
      console.log(`ℹ️ Aucun appareil en ligne pour ${uid}. Notification non envoyée.`);
      return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...data,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      tokens: onlineTokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    console.log(`✅ Notification envoyée à ${response.successCount} appareils.`);

    if (response.failureCount > 0) {
      let tokensToRemove = [];

      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const failedToken = onlineTokens[idx];
          console.warn(`❌ Token invalide : ${failedToken} - ${resp.error.message}`);
          tokensToRemove.push(failedToken);
        }
      });

      if (tokensToRemove.length > 0) {
        // Supprime les devices contenant les tokens invalides
        const updatedDevices = devices.filter(device => !tokensToRemove.includes(device.fcmToken));
        const userRef = db.collection('users').doc(uid);
        await userRef.update({ devices: updatedDevices });
        console.log(`✅ Tokens invalides supprimés de Firestore.`);
      }
    }

  } catch (error) {
    console.error("❌ Erreur lors de l'envoi:", error);
  }
}

// Exemple d'utilisation
const userUid = "mIVC7iInW2f0huaStswTlGrZBIn1";
sendNotificationIfOnline(
  userUid,
  "Nouvelle formation",
  "Vous êtes invité à une nouvelle formation !",
  { formationId: "abc123", type: "formation" }
);
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

// Récupère la clé API SendGrid configurée
const SENDGRID_API_KEY = functions.config().sendgrid.key;
sgMail.setApiKey(SENDGRID_API_KEY);

// Fonction déclenchée lors de la création d’une notification
exports.sendEmailOnNotification = functions.firestore
  .document('notifications/{notifId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data || !data.Useremail) {
      console.log("❌ Pas d'email dans la notification");
      return null;
    }

    const email = data.Useremail;
    const username = data.UserReceiver || "Utilisateur";
    const title = data.title || "Nouvelle notification";
    const body = data.body || "";

    const msg = {
      to: email,
      from: "no-reply@tondomaine.com",  // 🔁 adresse d'envoi autorisée dans SendGrid
      subject: title,
      text: `Bonjour ${username},\n\n${body}\n\nCordialement,\nL'équipe OLEA`,
      html: `<p>Bonjour <strong>${username}</strong>,</p><p>${body}</p><p>Cordialement,<br>L'équipe OLEA</p>`,
    };

    try {
      await sgMail.send(msg);
      console.log(`✅ Email envoyé à ${email}`);
    } catch (error) {
      console.error("❌ Erreur d’envoi email :", error);
    }

    return null;
  });
