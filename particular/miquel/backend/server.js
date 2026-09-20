require("dotenv").config();

const express = require("express");
const cors = require("cors");
const {
  GetCommand,
  ScanCommand,
  PutCommand
} = require("@aws-sdk/lib-dynamodb");

const { dbClient } = require("./db");

const app = express();

const port = Number(process.env.PORT) || 5000;
const tableName = process.env.DYNAMODB_TABLE_NAME || "races";

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Ruta informativa bàsica.
app.get("/", (req, res) => {
  res.status(200).json({
    service: "Half Marathon Backend API",
    status: "running",
    table: tableName
  });
});

// GET /races
// GET /races?id=race-001
// GET /races?city=Barcelona
// GET /races?country=Spain&date=2027-02-14
app.get("/races", async (req, res) => {
  try {
    const params = req.query;

    // Cerca directa per ID, ja que id és la partition key.
    if (params.id && Object.keys(params).length === 1) {
      const { Item } = await dbClient.send(
        new GetCommand({
          TableName: tableName,
          Key: {
            id: String(params.id)
          }
        })
      );

      if (!Item) {
        return res.status(404).json({
          error: "race not found"
        });
      }

      return res.status(200).json(Item);
    }

    let races = [];
    let lastKey;

    // Sense filtres: recupera totes les curses.
    if (Object.keys(params).length === 0) {
      do {
        const response = await dbClient.send(
          new ScanCommand({
            TableName: tableName,
            ExclusiveStartKey: lastKey
          })
        );

        races = races.concat(response.Items || []);
        lastKey = response.LastEvaluatedKey;
      } while (lastKey);

      return res.status(200).json(races);
    }

    // Amb filtres: genera una FilterExpression dinàmica.
    const attributeNames = {};
    const attributeValues = {};
    const filterExpressions = [];

    Object.entries(params).forEach(([key, value]) => {
      attributeNames[`#${key}`] = key;

      const numericValue = Number(value);
      attributeValues[`:${key}`] =
        value !== "" && Number.isFinite(numericValue)
          ? numericValue
          : String(value);

      filterExpressions.push(`#${key} = :${key}`);
    });

    do {
      const response = await dbClient.send(
        new ScanCommand({
          TableName: tableName,
          FilterExpression: filterExpressions.join(" AND "),
          ExpressionAttributeNames: attributeNames,
          ExpressionAttributeValues: attributeValues,
          ExclusiveStartKey: lastKey
        })
      );

      races = races.concat(response.Items || []);
      lastKey = response.LastEvaluatedKey;
    } while (lastKey);

    if (races.length === 0) {
      return res.status(404).json({
        error: "race not found"
      });
    }

    return res.status(200).json(races);
  } catch (error) {
    console.error("Error reading races from DynamoDB:", error);

    return res.status(500).json({
      error: "database error"
    });
  }
});

// POST /races
app.post("/races", async (req, res) => {
  try {
    const {
      name,
      city,
      country,
      date,
      web,
      distance
    } = req.body;

    if (!name || !city || !country || !date || distance === undefined) {
      return res.status(400).json({
        error:
          "name, city, country, date and distance are required"
      });
    }

    const parsedDistance = Number(distance);

    if (!Number.isFinite(parsedDistance) || parsedDistance <= 0) {
      return res.status(400).json({
        error: "distance must be a valid positive number"
      });
    }

    const id = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;

    const race = {
      id,
      name: String(name),
      city: String(city),
      country: String(country),
      date: String(date),
      web: web ? String(web) : "",
      distance: parsedDistance,
      source: "api",
      last_update: new Date().toISOString()
    };

    await dbClient.send(
      new PutCommand({
        TableName: tableName,
        Item: race,
        ConditionExpression: "attribute_not_exists(id)"
      })
    );

    return res.status(201).json({
      status: "ok",
      race
    });
  } catch (error) {
    console.error("Error creating race in DynamoDB:", error);

    return res.status(500).json({
      error: "database error"
    });
  }
});

// Health check real: comprova que l'API pot accedir a DynamoDB.
app.get("/health", async (req, res) => {
  try {
    await dbClient.send(
      new ScanCommand({
        TableName: tableName,
        Limit: 1
      })
    );

    return res.status(200).json({
      status: "ok",
      database: "connected",
      table: tableName
    });
  } catch (error) {
    console.error("Health check failed:", error);

    return res.status(503).json({
      status: "error",
      database: "disconnected"
    });
  }
});

app.listen(port, "0.0.0.0", () => {
  console.log(`Server listening on port ${port}`);
  console.log(`Using DynamoDB table: ${tableName}`);
});
