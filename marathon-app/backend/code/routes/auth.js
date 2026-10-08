const express = require("express");

const { cognitoClient, accessTokenVerifier, secretHash, CLIENT_ID } = require('../aws/cognito');
const {
  SignUpCommand, ConfirmSignUpCommand, InitiateAuthCommand, GlobalSignOutCommand
} = require("@aws-sdk/client-cognito-identity-provider");
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const COGNITO_ERRORS = {
  UsernameExistsException: 409,
  InvalidPasswordException: 400,
  InvalidParameterException: 400,
  CodeMismatchException: 400,
  ExpiredCodeException: 400,
  NotAuthorizedException: 401,
  UserNotFoundException: 401,
  UserNotConfirmedException: 403,
  TooManyRequestsException: 429,
  LimitExceededException: 429
};

function sendCognitoError(res, error) {
  const status = COGNITO_ERRORS[error.name];
  if (!status) {
    console.error(error);
    return res.status(500).json({ error: "auth error" });
  }
  res.status(status).json({ error: error.name, message: error.message });
}

router.post("/auth/signup", async (req, res) => {
  const { username, email, password } = req.body ?? {};
  if (!username || !email || !password) {
    return res.status(400).json({ error: "username, email and password required" });
  }
  if (username.includes("@")) {
    return res.status(400).json({ error: "username can't be an email" });
  }

  try {
    await cognitoClient.send(new SignUpCommand({
      ClientId: CLIENT_ID,
      SecretHash: secretHash(username),
      Username: username,
      Password: password,
      UserAttributes: [{ Name: "email", Value: email }]
    }));
    res.status(201).json({ status: "confirmation code sent" });
  } catch (error) {
    sendCognitoError(res, error);
  }
});

router.post("/auth/confirm", async (req, res) => {
  const { username, code } = req.body ?? {};
  if (!username || !code) return res.status(400).json({ error: "username and code required" });

  try {
    await cognitoClient.send(new ConfirmSignUpCommand({
      ClientId: CLIENT_ID,
      SecretHash: secretHash(username),
      Username: username,
      ConfirmationCode: code
    }));
    res.status(200).json({ status: "confirmed" });
  } catch (error) {
    sendCognitoError(res, error);
  }
});

router.post("/auth/login", async (req, res) => {
  const { username, password } = req.body ?? {};
  if (!username || !password) return res.status(400).json({ error: "username and password required" });

  try {
    const hash = secretHash(username);
    const { AuthenticationResult, ChallengeName } = await cognitoClient.send(new InitiateAuthCommand({
      AuthFlow: "USER_PASSWORD_AUTH",
      ClientId: CLIENT_ID,
      AuthParameters: {
        USERNAME: username,
        PASSWORD: password,
        ...(hash && { SECRET_HASH: hash })
      }
    }));

    // // e.g. NEW_PASSWORD_REQUIRED for users created from the console
    // if (!AuthenticationResult) {
    //   return res.status(409).json({ error: "challenge required", challenge: ChallengeName });
    // }

    // the real username, also when the user logged in with the email
    const { username: cognitoUsername } = await accessTokenVerifier.verify(AuthenticationResult.AccessToken);

    res.status(200).json({
      username: cognitoUsername,
      idToken: AuthenticationResult.IdToken,
      accessToken: AuthenticationResult.AccessToken,
      refreshToken: AuthenticationResult.RefreshToken,
      expiresIn: AuthenticationResult.ExpiresIn
    });
  } catch (error) {
    sendCognitoError(res, error);
  }
});

router.post("/auth/logout", requireAuth, async (req, res) => {
  try {
    await cognitoClient.send(new GlobalSignOutCommand({ AccessToken: req.accessToken }));
    res.status(200).json({ status: "logged out" });
  } catch (error) {
    sendCognitoError(res, error);
  }
});

module.exports = router;
