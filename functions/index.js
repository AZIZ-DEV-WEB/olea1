const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  databaseURL: "https://oleaone-beeeb.firebaseio.com"});

// 🔁 Nettoyage des utilisateurs non vérifiés (toutes les 24h)
exports.cleanupUnverifiedUsers = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
  const listUsersResult = await admin.auth().listUsers();
  const now = Date.now();

  const promises = listUsersResult.users.map(async (user) => {
    const creationTime = new Date(user.metadata.creationTime).getTime();
    const isExpired = now - creationTime > 24 * 60 * 60 * 1000;

    if (!user.emailVerified && isExpired) {
      console.log(`Suppression de l'utilisateur : ${user.email}`);
      return admin.auth().deleteUser(user.uid);
    }
  });

  await Promise.all(promises);
  console.log("✅ Nettoyage terminé.");
});


// 🔐 Transporteur mail sécurisé (⚠️ utilise un mot de passe d'application)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "azizfadhlaoui2k23@gmail.com",
    pass: functions.config().gmail.pass,  // ✅ sécurise via config
  },
});

// 📧 Envoi d’email lors de la création d’une notification
exports.sendNotificationEmail = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (!data.email || !data.title || !data.body) {
      console.error("❌ Champs manquants dans la notification:", data);
      return null;
    }

    const mailOptions = {
      from: "azizfadhlaoui2k23@gmail.com",
      to: data.email,
      subject: data.title,
      text: data.body,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`✅ Email envoyé à ${data.email}`);
    } catch (error) {
      console.error("❌ Erreur lors de l'envoi de l'email:", error);
    }
  });

  exports.sendNotificationOnNewDoc =
  functions.firestore.document("notifications/{notifId}")
    .onCreate(async (snap, ctx) => {
      const data = snap.data();
      const uid  = data.receiverUid;

      if (!uid) {
        console.log("⚠️  receiverUid manquant"); return null;
      }

      // 1️⃣  Récupération des tokens enregistrés
      const userDoc = await admin.firestore().collection("users").doc(uid).get();
      const tokens  = userDoc.data().fcmTokens || [];

      if (!tokens.length) {
        console.log(`ℹ️  Aucun token trouvé pour uid ${uid}`);
        return null;
      }

      // 2️⃣  Construction du message
      const message = {
        notification: {
          title: data.title || "Notification",
          body : data.body  || "",
        },
        tokens,                // envoi à tous les devices
        data : {               // ➜ accessible côté client (click_action, etc.)
          formationId : data.formationId || "",
          notifId     : ctx.params.notifId,
        },
      };

      // 3️⃣  Envoi
      const res = await admin.messaging().sendMulticast(message);
      console.log(`✅ Envoyé à ${res.successCount}/${tokens.length} tokens`);

      // 4️⃣  Nettoyage des tokens invalides
      const toRemove = [];
      res.responses.forEach((r, idx) => {
        if (!r.success) {
          const err = r.error.code;
          if (err === "messaging/registration-token-not-registered"
              || err === "messaging/invalid-registration-token") {
            toRemove.push(tokens[idx]);
          }
        }
      });
      if (toRemove.length) {
        await admin.firestore().doc(`users/${uid}`).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...toRemove),
        });
        console.log("♻️ Tokens invalides supprimés:", toRemove.length);
      }
      return null;
    });

