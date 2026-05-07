import mysql from 'mysql2/promise'

declare global {
    // eslint-disable-next-line no-var
    var __mysqlPool: mysql.Pool | undefined
}

// In development, Next.js hot-reloads modules which would create a new pool
// on every reload and exhaust MySQL's connection limit. We store the pool on
// the global object so it survives reloads and is reused.
const pool = global.__mysqlPool ?? mysql.createPool({
    host:            process.env.DB_HOST,
    port:            Number(process.env.DB_PORT),
    user:            process.env.DB_USER,
    password:        process.env.DB_PASSWORD,
    database:        process.env.DB_NAME,
    connectionLimit: 5,
    waitForConnections: true,
    queueLimit:      0,
})

if (process.env.NODE_ENV !== 'production') {
    global.__mysqlPool = pool
}

export default pool
