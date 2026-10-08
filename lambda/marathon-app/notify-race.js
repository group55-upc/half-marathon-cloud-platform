// index.mjs
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";
import { unmarshall } from "@aws-sdk/util-dynamodb";

const sns = new SNSClient({});
const TOPIC_ARN = process.env.TOPIC_ARN;

const toAsciiSubject = (text) =>
  text.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/[^\x20-\x7E]/g, "").slice(0, 99);

export const handler = async (event) => {
  for (const record of event.Records) {
    if (record.eventName !== "INSERT") continue;

    const race = unmarshall(record.dynamodb.NewImage);

    try {
      await sns.send(new PublishCommand({
        TopicArn: TOPIC_ARN,
        Subject: toAsciiSubject(`New race in ${race.country}: ${race.name}`),
        Message:
          `A new race from ${race.country} was published!\n\n` +
          `Race:     ${race.name}\n` +
          `City:     ${race.city}\n` +
          `Date:     ${race.date}\n` +
          `Distance: ${race.distance} km\n` +
          `Website:  ${race.web}\n`,
        MessageAttributes: {
          country: { DataType: "String", StringValue: race.country }
        }
      }));
      console.log(`Published race ${race.id} (${race.country})`);
    } catch (error) {
      console.error(`Failed to publish race ${race.id}`, error);
      return { batchItemFailures: [{ itemIdentifier: record.dynamodb.SequenceNumber }] };
    }
  }
  return { batchItemFailures: [] };
};
