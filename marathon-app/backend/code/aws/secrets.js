const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const SECRET_ID = process.env.SECRET_ID ?? "marathon-app/backend";

const secretsClient = new SecretsManagerClient({
  region: "us-east-1"
});

async function loadSecrets() {
  const { SecretString } = await secretsClient.send(new GetSecretValueCommand({ SecretId: SECRET_ID }));
  const secrets = JSON.parse(SecretString);
  for (const [key, value] of Object.entries(secrets)) {
    process.env[key] ??= value;
  }
}

module.exports = { loadSecrets };
