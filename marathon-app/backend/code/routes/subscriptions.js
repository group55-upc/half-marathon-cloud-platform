const express = require("express");

const { dbClient } = require('../aws/db');
const { GetCommand, PutCommand, DeleteCommand } = require("@aws-sdk/lib-dynamodb");
const { cognitoClient } = require('../aws/cognito');
const { GetUserCommand } = require("@aws-sdk/client-cognito-identity-provider");
const { snsClient, TOPIC_ARN } = require('../aws/sns');
const {
  SubscribeCommand, SetSubscriptionAttributesCommand, GetSubscriptionAttributesCommand, UnsubscribeCommand
} = require("@aws-sdk/client-sns");
const { COUNTRIES } = require('../constants/variables');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// race notifications: one SNS topic, one email subscription per user,
// and a filter policy with the user's countries. The Lambda publishes each new race
// with a "country" message attribute and SNS only delivers to the matching subscriptions.
// Table "subscriptions": PK userSub -> { countries (String Set), subscriptionArn }

async function getSubscriptionItem(userSub) {
  const { Item } = await dbClient.send(new GetCommand({
    TableName: "subscriptions",
    Key: { userSub }
  }));
  return Item;
}

// null if the subscription no longer exists in SNS (unsubscribed from the email link,
// or never confirmed and expired after 3 days)
async function getSubscriptionStatus(subscriptionArn) {
  try {
    const { Attributes } = await snsClient.send(new GetSubscriptionAttributesCommand({
      SubscriptionArn: subscriptionArn
    }));
    return { pending: Attributes.PendingConfirmation === "true" };
  } catch (error) {
    if (error.name === "NotFoundException") return null;
    throw error;
  }
}

router.get("/subscriptions", requireAuth, async (req, res) => {
  try {
    const item = await getSubscriptionItem(req.user.sub);
    if (!item) return res.status(200).json({ countries: [], pending: false });

    const status = await getSubscriptionStatus(item.subscriptionArn);
    if (!status) {
      await dbClient.send(new DeleteCommand({ TableName: "subscriptions", Key: { userSub: req.user.sub } }));
      return res.status(200).json({ countries: [], pending: false });
    }

    res.status(200).json({ countries: [...item.countries].sort(), pending: status.pending });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "subscription error" });
  }
});

router.put("/subscriptions", requireAuth, async (req, res) => {
  const countries = req.body?.countries;
  if (!Array.isArray(countries) || countries.length === 0) {
    return res.status(400).json({ error: "countries required" });
  }
  if (countries.some(c => !COUNTRIES.includes(c))) {
    return res.status(400).json({ error: "unknown country" });
  }
  if (countries.length > 150) {      // SNS limit of values per filter policy
    return res.status(400).json({ error: "too many countries" });
  }

  try {
    const filterPolicy = JSON.stringify({ country: countries });
    const item = await getSubscriptionItem(req.user.sub);
    const status = item ? await getSubscriptionStatus(item.subscriptionArn) : null;

    let subscriptionArn;
    if (status) {
      if (status.pending) {
        return res.status(409).json({ error: "subscription pending confirmation" });
      }
      subscriptionArn = item.subscriptionArn;
      await snsClient.send(new SetSubscriptionAttributesCommand({
        SubscriptionArn: subscriptionArn,
        AttributeName: "FilterPolicy",
        AttributeValue: filterPolicy
      }));
    } else {
      const { UserAttributes } = await cognitoClient.send(new GetUserCommand({ AccessToken: req.accessToken }));
      const email = UserAttributes.find(attr => attr.Name === "email").Value;

      const result = await snsClient.send(new SubscribeCommand({
        TopicArn: TOPIC_ARN,
        Protocol: "email",
        Endpoint: email,
        Attributes: { FilterPolicy: filterPolicy },
        ReturnSubscriptionArn: true      // without it, SNS returns "pending confirmation" instead of the ARN
      }));
      subscriptionArn = result.SubscriptionArn;
    }

    await dbClient.send(new PutCommand({
      TableName: "subscriptions",
      Item: {
        userSub: req.user.sub,
        countries: new Set(countries),
        subscriptionArn: subscriptionArn
      }
    }));

    res.status(200).json({ status: "ok", pending: !status });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "subscription error" });
  }
});

router.delete("/subscriptions", requireAuth, async (req, res) => {
  try {
    const item = await getSubscriptionItem(req.user.sub);
    if (item) {
      try {
        await snsClient.send(new UnsubscribeCommand({ SubscriptionArn: item.subscriptionArn }));
      } catch (error) {
        console.log(error);              // already removed from the email link
      }
      await dbClient.send(new DeleteCommand({ TableName: "subscriptions", Key: { userSub: req.user.sub } }));
    }
    res.status(200).json({ status: "unsubscribed" });
  } catch (error) {
    console.log(error);
    res.status(500).json({ error: "subscription error" });
  }
});

module.exports = router;
