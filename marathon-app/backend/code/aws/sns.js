const { SNSClient } = require("@aws-sdk/client-sns");

const TOPIC_ARN = process.env.TOPIC_ARN ?? "arn:aws:sns:us-east-1:497553624665:marathon-app";

const snsClient = new SNSClient({
  region: "us-east-1"
});

module.exports = { snsClient, TOPIC_ARN };
