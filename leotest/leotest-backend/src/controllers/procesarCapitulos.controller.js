// src/controllers/procesarCapitulos.controller.js
import fetch from "node-fetch";
import pool from "../db/connection.js";
import OpenAI from "openai";
import { createRequire } from "module";
const require = createRequire(import.meta.url);
const pdfParse = require("pdf-parse");

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Función para dividir texto en chunks razonables
function dividirEnChunks(texto, maxLen = 800) {
  const palabras = texto.split(" ");
  const chunks = [];
  let actual = [];

  for (const palabra of palabras) {
    if ((actual.join(" ").length + palabra.length) < maxLen) {
      actual.push(palabra);
    } else {
      chunks.push(actual.join(" "));
      actual = [palabra];
    }
  }
  if (actual.length > 0) chunks.push(actual.join(" "));
  return chunks;
}

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

export const procesarCapitulos = async (req, res) => {
  const { id_libro } = req.params;

  try {
    const { rows } = await pool.query(
      "SELECT ruta_archivo FROM libro WHERE id_libro = $1",
      [id_libro]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: "Libro no encontrado" });
    }

    const pdfUrl = rows[0].ruta_archivo;

    const response = await fetch(pdfUrl);
    if (!response.ok) {
      throw new Error(`Error al descargar PDF: ${response.statusText}`);
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    const data = await pdfParse(buffer);
    const texto = data.text;

    // Detectar capítulos por números romanos y números como títulos solos
    const partes = texto.split(/\n\s*(CAPÍTULO\s+\d+|Capítulo\s+\d+|CAPITULO\s+\d+|\b[IVXLCDM]+\b|\b\d+\b)\s*\n/g);


    if (partes.length <= 1) {
      return res.status(400).json({
        error: "No se detectaron capítulos. Se requiere división manual."
      });
    }

    for (let i = 1; i < partes.length; i++) {
      const numero = i;
      const contenido = partes[i].trim();

      const insert = await pool.query(
        "INSERT INTO capitulo (id_libro, numero_capitulo, titulo_capitulo) VALUES ($1, $2, $3) RETURNING id_capitulo",
        [id_libro, numero, `Capítulo ${numero}`]
      );

      const id_capitulo = insert.rows[0].id_capitulo;

      // Dividir texto del capítulo en chunks
      const chunks = dividirEnChunks(contenido);

      for (const chunk of chunks) {
        const embeddingRes = await openai.embeddings.create({
          model: "text-embedding-3-small",
          input: chunk,
        });

        const embedding = embeddingRes.data[0].embedding;

        await pool.query(
          "INSERT INTO capitulo_embedding (id_capitulo, contenido_texto, embedding) VALUES ($1, $2, $3)",
          [id_capitulo, chunk, embedding]
        );

        await sleep(300); // Pequeña pausa para no exceder el límite
      }
    }

    res.json({ success: true, mensaje: "Capítulos procesados y embebidos correctamente." });

  } catch (error) {
    console.error("Error procesando capítulos:", error);
    res.status(500).json({ error: error.message });
  }
};
