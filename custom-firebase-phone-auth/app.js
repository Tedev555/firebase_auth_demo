const admin = require("firebase-admin");
const app = require("express")();
var express = require("express");
// Create a service account and download its JSON key file.
const serviceAccount = require("./firebaseKey.json");

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

try {
  admin.initializeApp({
    // Initialize Firebase Admin SDK configuration
    credential: admin.credential.cert(serviceAccount),
  });
} catch (err) {
  console.log("Firebase admin initialization error", err.stack);
}

app.get("/", (req, res) => {
  res.send("Hello World!");
});

app.post("/setCustomClaims", async (req, res) => {
  try {
    const idToken = req.body.token;

    // Verify the ID token and decode its payload.
    const claims = await admin.auth().verifyIdToken(idToken);

    // Verify user is eligible for additional privileges.
    if (typeof claims.phone_number !== "undefined" && claims.phone_number) {
      // Add custom claims for additional privileges.
      await admin.auth().setCustomUserClaims(claims.sub, {
        admin: true,
      });

      // Tell client to refresh token on user.
      res.status(200).json({ status: "success" });
    } else {
      // Return nothing.
      res.end(JSON.stringify({ status: "ineligible" }));
    }
  } catch (error) {
    console.log(error);
    res.status(401).json({ status: "error", error });
  }
});

app.get("/verify", async (req, res) => {
  try {
    // Retrieve token from request header "Authorization"
    const idToken = req.headers.authorization.split("Bearer ")[1];
    const claims = await admin.auth().verifyIdToken(idToken);
    // Find the user by uid
    const user = await admin.auth().getUser(claims.sub);

    // Get custom claims from user
    const customClaims = user.customClaims;
    res.status(200).json({ status: "success", customClaims });
  } catch (error) {
    res.status(401).json({ status: "error", error });
  }
});

app.listen(3000, () => {
  console.log("App listening on port 3000!");
});
