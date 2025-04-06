const functions = require("firebase-functions");
const admin = require("firebase-admin");
const { KeyManagementServiceClient } = require("@google-cloud/kms");

admin.initializeApp();

const kmsClient = new KeyManagementServiceClient();
const projectId = "voting-1da7b";
const locationId = "global";
const keyRingId = "vote-encryption-key-ring";
const keyId = "vote-encryption-key";

const keyName = kmsClient.cryptoKeyPath(projectId, locationId, keyRingId, keyId);

function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

exports.recordEncryptedVote = functions.https.onRequest(async (request, response) => {
  response.set('Access-Control-Allow-Origin', '*');
  response.set('Access-Control-Allow-Methods', 'POST');
  response.set('Access-Control-Allow-Headers', 'Content-Type');

  if (request.method === 'OPTIONS') {
    return response.status(204).send('');
  }

  if (request.method !== "POST") {
    return response.status(405).send({ status: "error", message: "Method not allowed. Use POST." });
  }

  const { candidateId, boothId, timestamp, gender, latitude, longitude, aadhaarNumber } = request.body;

  if (!candidateId || !boothId || !timestamp || !gender || latitude == null || longitude == null || !aadhaarNumber) {
    return response.status(400).send({
      status: "error",
      message: "Missing required fields: candidateId, boothId, timestamp, gender, latitude, longitude, aadhaarNumber",
    });
  }

  if (typeof latitude !== 'number' || latitude < -90 || latitude > 90) {
    return response.status(400).send({
      status: "error",
      message: "Invalid latitude value. Must be a number between -90 and 90.",
    });
  }
  if (typeof longitude !== 'number' || longitude < -180 || longitude > 180) {
    return response.status(400).send({
      status: "error",
      message: "Invalid longitude value. Must be a number between -180 and 180.",
    });
  }

  const db = admin.firestore();
  const boothRef = db.collection("booths").doc(boothId);
  const boothDoc = await boothRef.get();

  if (!boothDoc.exists) {
    return response.status(400).send({
      status: "error",
      message: `Booth with ID ${boothId} does not exist.`,
    });
  }

  const boothData = boothDoc.data();
  const votingStartHour = boothData.votingStartHour || 9;
  const votingEndHour = boothData.votingEndHour || 17;
  const boothLatitude = boothData.latitude;
  const boothLongitude = boothData.longitude;
  const acceptableRadiusKm = boothData.acceptableRadiusKm || 1;

  const voteTimestamp = new Date(timestamp);
  const voteHour = voteTimestamp.getHours();
  let votingHoursAnomaly = false;
  if (voteHour < votingStartHour || voteHour >= votingEndHour) {
    votingHoursAnomaly = true;
    const anomalyId = aadhaarNumber;
    await db.collection("anomalies").doc(anomalyId).set({
      type: "voting_hours",
      boothId: boothId,
      aadhaarNumber: aadhaarNumber,
      timestamp: timestamp,
      voteHour: voteHour,
      expectedStartHour: votingStartHour,
      expectedEndHour: votingEndHour,
      message: `Vote recorded outside expected hours (expected: ${votingStartHour}:00 - ${votingEndHour}:00, actual: ${voteHour}:00)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  const distance = calculateDistance(latitude, longitude, boothLatitude, boothLongitude);
  let locationAnomaly = false;
  if (distance > acceptableRadiusKm) {
    locationAnomaly = true;
    const anomalyId = aadhaarNumber;
    await db.collection("anomalies").doc(anomalyId).set({
      type: "location",
      boothId: boothId,
      aadhaarNumber: aadhaarNumber,
      timestamp: timestamp,
      voterLatitude: latitude,
      voterLongitude: longitude,
      boothLatitude: boothLatitude,
      boothLongitude: boothLongitude,
      distanceKm: distance,
      acceptableRadiusKm: acceptableRadiusKm,
      message: `Vote recorded from a location ${distance.toFixed(2)} km away from the booth (acceptable radius: ${acceptableRadiusKm} km)`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }

  if (votingHoursAnomaly || locationAnomaly) {
    console.log(`Anomaly detected for Aadhaar ${aadhaarNumber} in booth ${boothId}: votingHours=${votingHoursAnomaly}, location=${locationAnomaly}`);
  }

  const plaintext = Buffer.from(candidateId, "utf8");
  const [encryptResponse] = await kmsClient.encrypt({
    name: keyName,
    plaintext: plaintext,
  });

  const encryptedCandidateId = encryptResponse.ciphertext.toString("base64");

  await db
    .collection("votes")
    .doc(boothId)
    .collection("booth")
    .doc(encryptedCandidateId)
    .set({});

  const analyticsRef = db.collection("analytics").doc(`booth_${boothId}`);
  await db.runTransaction(async (transaction) => {
    const analyticsDoc = await transaction.get(analyticsRef);
    if (!analyticsDoc.exists) {
      transaction.set(analyticsRef, {
        boothId: boothId,
        totalVotes: 1,
        totalMale: gender === "male" ? 1 : 0,
        totalFemale: gender === "female" ? 1 : 0,
      });
    } else {
      const currentData = analyticsDoc.data() || {};
      transaction.update(analyticsRef, {
        totalVotes: (currentData.totalVotes || 0) + 1,
        totalMale: (currentData.totalMale || 0) + (gender === "male" ? 1 : 0),
        totalFemale: (currentData.totalFemale || 0) + (gender === "female" ? 1 : 0),
      });
    }
  });

  return response.status(200).send({ status: "success", message: "Vote recorded successfully" });
});