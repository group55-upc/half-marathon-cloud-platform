const crypto = require("crypto");
const { CognitoIdentityProviderClient } = require("@aws-sdk/client-cognito-identity-provider");
const { CognitoJwtVerifier } = require("aws-jwt-verify");

const USER_POOL_ID = process.env.USER_POOL_ID;
const CLIENT_ID = process.env.CLIENT_ID;
const CLIENT_SECRET = process.env.CLIENT_SECRET;

const cognitoClient = new CognitoIdentityProviderClient({
  region: "us-east-1"
});

const accessTokenVerifier = CognitoJwtVerifier.create({
  userPoolId: USER_POOL_ID,
  tokenUse: "access",
  clientId: CLIENT_ID
});

function secretHash(username) {
  if (!CLIENT_SECRET) return undefined;
  return crypto.createHmac("sha256", CLIENT_SECRET)
    .update(username + CLIENT_ID)
    .digest("base64");
}

module.exports = { cognitoClient, accessTokenVerifier, secretHash, CLIENT_ID };
