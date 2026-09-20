//require("dotenv").config();
const express = require("express");
const cors = require("cors");                   // <- tema de seguretat per limitar desde on es poden fer les crides a la API, de moment esta deactvitat 
//const jwt = require("jsonwebtoken");             <- gestió de jwt per futurs usuaris
//const cookieparser = require("cookie-parser");   <- això serveix per poder fer les cookies HttpOnly i tindre un millor xifrat, maxAge, etc
const multer = require("multer");

const { dbClient } = require('./db');
const { GetCommand, ScanCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");
const { s3Client } = require('./s3');
const { PutObjectCommand } = require("@aws-sdk/client-s3");


const app = express();
const port = 5000;

const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());                            // dades en application/json
app.use(express.urlencoded({ extended: true }));    //dades en application/x-www-form-urlencoded

const ALLOWED_TRACK_EXT = ["geojson", "kml", "gpx"];

app.get("/races", async (req, res) => {
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


app.post("/races", upload.single("track"), async (req, res) => {
    try {
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
                name: req.body.name,
                city: req.body.city,
                country: req.body.country,
                date: req.body.date,
                web: req.body.web,
                distance: req.body.distance,
                trackUrl: trackUrl,
                trackType: trackType
            }
        }));

        res.status(200).json({ status: "ok" });

    } catch (error) {
        res.status(500).json({ error: "database error" });
    }
});



app.get("/connection", async (req, res) => {
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

app.get("/", async (req, res) => {
    try  {
        res.status(200).json({status: "ok"})
    } catch (error) {
        res.status(500).json({status: "error"})
    }   
});


app.listen(port, () => {
    console.log(`Server listening on port ${port}`)
});
