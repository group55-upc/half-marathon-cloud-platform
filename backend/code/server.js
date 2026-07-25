//require("dotenv").config();
const express = require("express");
const cors = require("cors");                   // <- tema de seguretat per limitar desde on es poden fer les crides a la API, de moment esta deactvitat 
//const jwt = require("jsonwebtoken");             <- gestió de jwt per futurs usuaris
//const cookieparser = require("cookie-parser");   <- això serveix per poder fer les cookies HttpOnly i tindre un millor xifrat, maxAge, etc

const { dbClient } = require('./db');
const { GetCommand, ScanCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const app = express();
const port = 5000;

app.use(cors())
app.use(express.json());                            // dades en application/json
app.use(express.urlencoded({ extended: true }));    //dades en application/x-www-form-urlencoded



//id, name, city, country, date, web, distance, file(?) <- NO CONTEMPLA OBTENIR FITXERS (DE MOMENT)
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
      paramValues[`:${key}`] = value; isNaN(value) ? value : Number(value);
      filter.push(`#${key} = :${key}`);
    });

    // console.log("FilterExpression:", filter.join(" AND "));
    // console.log("ExpressionAttributeNames:", JSON.stringify(paramNames));
    // console.log("ExpressionAttributeValues:", JSON.stringify(paramValues));

    do {
        const { Items, LastEvaluatedKey } = await dbClient.send(new ScanCommand({
            TableName: "races",
            FilterExpression: filter.join(" AND "),
            ExpressionAttributeNames: paramNames,
            ExpressionAttributeValues: paramValues,
            ExclusiveStartKey: lastKey
        }));
        // console.log(Items);
        races = races.concat(Items);
        lastKey = LastEvaluatedKey;
    } while (lastKey);

    if (!races.length) return res.status(404).json({ error: "race not found" });
    // console.log(races)
    res.status(200).json(races);

  } catch (error) {
    // console.error("Database error:", error);
    res.status(500).json({ error: "database error" });
  }
});

//FALTA UN METODE PER GENERAR ID RANDOM; dynamo es noSQL, no te id
//hi ha un paqurt que es diu uuid que tmb genera id random, pero es crfear una dependencia d'un paquet
// const id = uuidv4(); #npm install uuid
// primer de tot seria ingresar el file, que retorni el path i afeguir el path en la mateixa crida de Put de la carrera,
// de manera que aixi ens estalviem una trucada a dynamo -> -$
//id, name, city, country, date, web, distance, file(?) <- NO CONTEMPLA PUJAR FITXERS (DE MOMENT)
app.post("/races", async (req, res) => {
    try {
        const id = `${Date.now()}-${Math.floor(Math.random() * 10000)}`;
        const response = await dbClient.send(new PutCommand({
            TableName: "races",
            Item: {
                id: id,
                name: req.body.name,
                city: req.body.city,
                country: req.body.country,
                date: req.body.date,
                web: req.body.web,
                distance: req.body.distance
            }
        }))
        // console.log(response);
        res.status(200).json({status: "ok"});

    } catch (error) {
        res.status(500).json({error: "database error"})
    }
});


// curl -X POST http://localhost:5000/races \
//   -H "Content-Type: application/json" \
//   -d '{
//     "name": "Madrid Marathon",
//     "city": "Madrid",
//     "country": "Spain",
//     "date": "2026-03-15",
//     "web": "https://madridmarathon.com",
//     "distance": 42
//   }'

// curl -X POST http://localhost:5000/races \
//   -H "Content-Type: application/json" \
//   -d '{
//     "name": "Barcelona Marathon",
//     "city": "Barcelona",
//     "country": "Spain",
//     "date": "2026-03-15",
//     "web": "https://barcelonamarathon.com",
//     "distance": 42
//   }'

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
