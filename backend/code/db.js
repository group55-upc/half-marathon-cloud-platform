//require("dotenv").config();
const { DynamoDBClient } = require ("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, PutCommand, UpdateCommand, DeleteCommand, ScanCommand } = require ("@aws-sdk/lib-dynamodb");

const connection = new DynamoDBClient({
  region: "us-east-1"
});

const dbClient = DynamoDBDocumentClient.from(connection);

module.exports = { connection, dbClient };
