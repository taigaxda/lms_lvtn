import dotenv from "dotenv/config";
import admin from "firebase-admin";
import admin from "firebase-admin";
import fs from "fs";

let serviceAccount;

if (process.env.FIREBASE_KEY) {
  serviceAccount = JSON.parse(process.env.FIREBASE_KEY);
  serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, '\n');
} else {
  serviceAccount = JSON.parse(
    fs.readFileSync("./ggfcmkey.json", "utf8")
  );
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});