require("dotenv").config();

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");

const connection = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1"
});

const dbClient = DynamoDBDocumentClient.from(connection);

module.exports = { connection, dbClient };
