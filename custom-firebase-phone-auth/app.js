const admin = require("firebase-admin");
const app = require("express")();

// Create a service account and download its JSON key file.
const serviceAccount = require("./firebaseKey.json");

try {
  admin.initializeApp({
    // Initialize Firebase Admin SDK configuration
    credential: admin.credential.cert(serviceAccount),
  });
} catch (err) {
  console.log("Firebase admin initialization error", err.stack);
}

// Send verification code to user's phone number
const phoneNumber = "+8562058888059"; // Replace with the user's actual phone number
const verificationCode = "123456"; // Replace with the generated verification code

app.get("/", (req, res) => {
  res.send("Hello World!");
});

app.post("/setCustomClaims", async (req, res) => {
  // Get the ID token passed from bearer token
  try {
    const idToken = req.headers.authorization.split("Bearer ")[1];

    // Verify the ID token and decode its payload.
    const claims = await admin.auth().verifyIdToken(idToken);
    console.log("claims", claims);

    // Verify user is eligible for additional privileges.
    if (
      typeof claims.email !== "undefined" &&
      typeof claims.email_verified !== "undefined" &&
      claims.email_verified &&
      claims.email.endsWith("@admin.example.com")
    ) {
      // Add custom claims for additional privileges.
      // await admin.getAuth().setCustomUserClaims(claims.sub, {
      //   admin: true,
      // });
      await admin.getAuth().setCustomUserClaims(claims.sub, {
        admin: true,
      });

      // Tell client to refresh token on user.
      res.status(200).json({ status: "success", idToken });
    } else {
      // Return nothing.
      res.end(JSON.stringify({ status: "ineligible" }));
    }
  } catch (error) {
    console.log(error);
    res.status(401).json({ status: "error", error });
  }
});

app.listen(3000, () => {
  console.log("App listening on port 3000!");
});
