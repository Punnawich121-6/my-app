import mysql from 'mysql2/promise';

declare global {
  var _mysqlPool: mysql.Pool | undefined
}

// Vercel serverless: reuse pool across warm invocations via global
// connectionLimit=10 to handle concurrent serverless instances
const pool = global._mysqlPool ?? mysql.createPool({
  host:             process.env.DB_HOST,
  port:             Number(process.env.DB_PORT ?? 3306),
  user:             process.env.DB_USER,
  password:         process.env.DB_PASSWORD,
  database:         process.env.DB_NAME,
  connectionLimit:  10,
  waitForConnections: true,
  queueLimit:       0,
  enableKeepAlive:  true,
  keepAliveInitialDelay: 0,
  // Required for PlanetScale / cloud MySQL with SSL
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: true } : undefined,
})

// Cache pool in global so hot-reloads (dev) and warm Vercel instances reuse it
global._mysqlPool = pool

export default pool;
