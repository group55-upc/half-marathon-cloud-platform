/**
 * import-races
 *
 * Funcion Lambda de importacion periodica de carreras.
 *
 * La invoca EventBridge una vez por semana. Su trabajo:
 *
 *   1. Lee un fichero JSON con carreras desde el bucket de S3
 *   2. Consulta que carreras ya existen en DynamoDB
 *   3. Inserta unicamente las que no estaban (idempotente)
 *   4. Publica un resumen en el tema de SNS
 *
 * Idempotencia: se considera que dos carreras son la misma si coinciden su
 * nombre y su fecha. Asi la funcion puede ejecutarse tantas veces como se
 * quiera sin duplicar datos, requisito imprescindible en un proceso
 * automatico que nadie supervisa.
 *
 * No tiene dependencias externas: el SDK de AWS v3 viene incluido en el
 * runtime de Node.js de Lambda, por lo que no hay que empaquetar node_modules.
 */

import { S3Client, GetObjectCommand } from "@aws-sdk/client-s3";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, ScanCommand, PutCommand } from "@aws-sdk/lib-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const REGION = process.env.AWS_REGION || "us-east-1";

const s3  = new S3Client({ region: REGION });
const ddb = DynamoDBDocumentClient.from(new DynamoDBClient({ region: REGION }));
const sns = new SNSClient({ region: REGION });

const TABLA   = process.env.TABLE_NAME;
const BUCKET  = process.env.BUCKET_NAME;
const CLAVE   = process.env.IMPORT_KEY || "imports/races.json";
const TEMA    = process.env.SNS_TOPIC_ARN;

/** Clave logica de deduplicacion: nombre + fecha, normalizados. */
const claveLogica = (c) => `${(c.name || "").trim().toLowerCase()}|${(c.date || "").trim()}`;

/** Genera un identificador con el mismo formato que usa la API. */
const nuevoId = () => `${Date.now()}-${Math.floor(Math.random() * 10000)}`;

/** Valida que una carrera del fichero traiga los campos imprescindibles. */
function esValida(c) {
  return (
    c &&
    typeof c.name === "string"     && c.name.trim() !== "" &&
    typeof c.city === "string"     && c.city.trim() !== "" &&
    typeof c.country === "string"  && c.country.trim() !== "" &&
    typeof c.date === "string"     && /^\d{4}-\d{2}-\d{2}$/.test(c.date) &&
    !isNaN(Number(c.distance))     && Number(c.distance) > 0
  );
}

async function leerFicheroDeS3() {
  try {
    const { Body } = await s3.send(new GetObjectCommand({ Bucket: BUCKET, Key: CLAVE }));
    const texto = await Body.transformToString();
    const datos = JSON.parse(texto);
    if (!Array.isArray(datos)) {
      throw new Error("El fichero debe contener un array de carreras");
    }
    return datos;
  } catch (error) {
    if (error.name === "NoSuchKey") {
      console.log(`No existe s3://${BUCKET}/${CLAVE}. Nada que importar.`);
      return null;
    }
    throw error;
  }
}

async function leerCarrerasExistentes() {
  const existentes = new Set();
  let lastKey;
  do {
    const { Items, LastEvaluatedKey } = await ddb.send(new ScanCommand({
      TableName: TABLA,
      ProjectionExpression: "#n, #d",
      ExpressionAttributeNames: { "#n": "name", "#d": "date" },
      ExclusiveStartKey: lastKey
    }));
    (Items || []).forEach((i) => existentes.add(claveLogica(i)));
    lastKey = LastEvaluatedKey;
  } while (lastKey);
  return existentes;
}

async function notificar(asunto, cuerpo) {
  if (!TEMA) {
    console.log("Sin SNS_TOPIC_ARN configurado, no se notifica.");
    return;
  }
  await sns.send(new PublishCommand({
    TopicArn: TEMA,
    Subject: asunto.slice(0, 100),   // SNS limita el asunto a 100 caracteres
    Message: cuerpo
  }));
}

export const handler = async () => {
  const inicio = Date.now();
  console.log(`Importacion iniciada. Tabla=${TABLA} Origen=s3://${BUCKET}/${CLAVE}`);

  try {
    const candidatas = await leerFicheroDeS3();

    if (candidatas === null) {
      // Ausencia de fichero no es un error: simplemente no hay nada que hacer.
      return { ok: true, importadas: 0, motivo: "fichero de importacion no encontrado" };
    }

    const existentes = await leerCarrerasExistentes();
    console.log(`${existentes.size} carreras ya en la base de datos, ${candidatas.length} en el fichero`);

    let importadas = 0;
    let duplicadas = 0;
    const invalidas = [];

    for (const carrera of candidatas) {
      if (!esValida(carrera)) {
        invalidas.push(carrera?.name || "(sin nombre)");
        continue;
      }
      if (existentes.has(claveLogica(carrera))) {
        duplicadas++;
        continue;
      }

      await ddb.send(new PutCommand({
        TableName: TABLA,
        Item: {
          id:       nuevoId(),
          name:     carrera.name.trim(),
          city:     carrera.city.trim(),
          country:  carrera.country.trim(),
          date:     carrera.date.trim(),
          web:      (carrera.web || "").trim(),
          distance: Number(carrera.distance)
        }
      }));

      existentes.add(claveLogica(carrera));
      importadas++;
      console.log(`Importada: ${carrera.name}`);
    }

    const segundos = ((Date.now() - inicio) / 1000).toFixed(1);
    const resumen = [
      "Importacion semanal de carreras completada.",
      "",
      `Nuevas carreras importadas: ${importadas}`,
      `Ya existentes (omitidas):   ${duplicadas}`,
      `Registros invalidos:        ${invalidas.length}`,
      invalidas.length ? `  -> ${invalidas.join(", ")}` : "",
      `Total en la base de datos:  ${existentes.size}`,
      "",
      `Duracion: ${segundos} s`,
      `Origen:   s3://${BUCKET}/${CLAVE}`
    ].filter(Boolean).join("\n");

    console.log(resumen);

    // Solo se notifica si hubo algo digno de mencion, para no generar
    // correo semanal sin contenido.
    if (importadas > 0 || invalidas.length > 0) {
      await notificar(
        `Marathon: ${importadas} carreras importadas`,
        resumen
      );
    }

    return { ok: true, importadas, duplicadas, invalidas: invalidas.length };

  } catch (error) {
    console.error("Fallo la importacion:", error);
    await notificar(
      "Marathon: ha fallado la importacion de carreras",
      `La funcion import-races ha terminado con error.\n\n${error.name}: ${error.message}`
    ).catch(() => { /* si tambien falla SNS, no ocultar el error original */ });
    throw error;
  }
};
