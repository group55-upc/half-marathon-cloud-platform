require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { loadSecrets } = require('./aws/secrets');

const app = express();
const port = 5000;

app.use(cors());
app.use(express.json());                            // dades en application/json
app.use(express.urlencoded({ extended: true }));    //dades en application/x-www-form-urlencoded

app.get("/", async (req, res) => {
    try  {
        res.status(200).json({status: "ok"})
    } catch (error) {
        res.status(500).json({status: "error"})
    }
});

async function start() {
  await loadSecrets();

  app.use(require('./routes/races'));
  app.use(require('./routes/auth'));
  app.use(require('./routes/subscriptions'));

  app.listen(port, () => {
      console.log(`Server listening on port ${port}`)
  });
}

start().catch(error => {
  console.error("Could not load the secrets from Secrets Manager", error);
  process.exit(1);
});
