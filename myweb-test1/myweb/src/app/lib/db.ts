import mysql from 'mysql2/promise';

// ประกาศตัวแปร global._mysqlPool
declare global{
    var _mysqlPool : mysql.Pool | undefined
}

const pool = global._mysqlPool  ?? mysql.createPool({
    host:process.env.DB_HOST,
    port:Number(process.env.DB_PORT),
    user:process.env.DB_USER,
    password:process.env.DB_PASSWORD,
    database:process.env.DB_NAME,
    connectionLimit:5,
    waitForConnections: true,
    queueLimit: 0,
})

if (process.env.NODE_ENV !== 'production'){
    global._mysqlPool = pool
}

export default pool;