// testConnection.js
import pool from "./connection.js";

const test = async () => {
  try {
    const res = await pool.query("SELECT NOW()");
    console.log("✅ Conexión exitosa a Supabase:", res.rows[0]);
  } catch (err) {
    console.error("❌ Error en la conexión:", err.message);
  } finally {
    await pool.end();
  }
};

test();
