const express = require("express");
const multer = require("multer");

const { dbClient } = require('../aws/db');
const { GetCommand, ScanCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { s3Client } = require('../aws/s3');
const { PutObjectCommand } = require("@aws-sdk/client-s3");
const { COUNTRIES } = require('../constants/variables');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });   // 10 MB maxim per track


router.get("/races", async (req, res) => {
  try {
    const params = req.query;

    let races = [];
    let lastKey = undefined;

    if (Object.keys(params).length === 0) {  // si esta buit, busca totes (/races)

      do {
        const { Items, LastEvaluatedKey } = await dbClient.send(new ScanCommand({
          TableName: "races",
          ExclusiveStartKey: lastKey       // aixo es per si retorna mes de 1MB, que es veu de dynamo pot retornar maxim 1MB per request
        }));
        races = races.concat(Items);
        lastKey = LastEvaluatedKey;
      } while (lastKey);

      return res.status(200).json(races);
    }
    
    if (params.id && Object.keys(params).length === 1) {   // si unicament busca la id, busca amb getcommand que es directe per PK
      const { Item } = await dbClient.send(new GetCommand({
        TableName: "races",
        Key: { id: params.id }
      }));
      if (!Item) return res.status(404).json({ error: "race not found" });
      return res.status(200).json(Item);
    }

    const paramNames = {};
    const paramValues = {};
    const filter = [];

    Object.entries(params).forEach(([key, value]) => {
      paramNames[`#${key}`] = key;       // el # es pq utilitzi valor nostres i no metadates de la base de dades
      paramValues[`:${key}`] = isNaN(value) ? value : Number(value);
      filter.push(`#${key} = :${key}`);
    });

    do {
        const { Items, LastEvaluatedKey } = await dbClient.send(new ScanCommand({
            TableName: "races",
            FilterExpression: filter.join(" AND "),
            ExpressionAttributeNames: paramNames,
            ExpressionAttributeValues: paramValues,
            ExclusiveStartKey: lastKey
        }));
        races = races.concat(Items);
        lastKey = LastEvaluatedKey;
    } while (lastKey);

    if (!races.length) return res.status(404).json({ error: "race not found" });
    res.status(200).json(races);

  } catch (error) {
    res.status(500).json({ error: "database error" });
  }
});

const ALLOWED_TRACK_EXT = ["geojson", "kml", "gpx"];
const REQUIRED_RACE_FIELDS = ["name", "city", "country", "date", "web", "distance"];

router.post("/races", requireAuth, upload.single("track"), async (req, res) => {
    try {
        const body = req.body ?? {};

        const missing = REQUIRED_RACE_FIELDS.filter(field =>
            typeof body[field] !== "string" || body[field].trim() === ""
        );
        if (missing.length) {
            return res.status(400).json({ error: "missing fields"});
        }
        if (!COUNTRIES.includes(body.country.trim())) {
            return res.status(400).json({ error: "unknown country" });
        }

        const id = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;

        let trackUrl = null;
        let trackType = null;

        if (req.file) {
            const ext = req.file.originalname.split(".").pop().toLowerCase();
            if (!ALLOWED_TRACK_EXT.includes(ext)) {
                return res.status(400).json({ error: "unsupported track file type" });
            }

            const key = `tracks/${id}.${ext}`;

            await s3Client.send(new PutObjectCommand({
                Bucket: "fpcmarathon-tracks",
                Key: key,
                Body: req.file.buffer,
                ContentType: req.file.mimetype
            }));

            trackUrl = `https://fpcmarathon-tracks.s3.amazonaws.com/${key}`;
            trackType = ext;
        }

        await dbClient.send(new PutCommand({
            TableName: "races",
            Item: {
                id: id,
                user: req.user.sub,              
                name: body.name.trim(),
                city: body.city.trim(),
                country: body.country.trim(),
                date: body.date,
                web: body.web.trim(),
                distance: body.distance,         
                trackUrl: trackUrl,
                trackType: trackType
            }
        }));

        res.status(200).json({ status: "ok" });

    } catch (error) {
        res.status(500).json({ error: "database error" });
        console.log(error)
    }
});

router.get("/connection", async (req, res) => {
    try  {
        const test = await dbClient.send(new ScanCommand({
            TableName: "races",
            Limit: 1
        }))
        res.status(200).json({status: "ok"})
    } catch (error) {
        res.status(500).json({status: "error"})
    }   
});

module.exports = router;
