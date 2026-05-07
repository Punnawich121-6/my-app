import pool from './db'

const PAGE_SIZE = 10

export type Restaurant = {
    id: string
    name: string
    category: string
    rating: number
    totalOrders: number
    status: string
    imageUrl: string | null
    address: string
    phone: string
    email: string
    owner_name: string | null
    line_id: string | null
    bank_name: string | null
    account_name: string | null
    account_no: string | null
    id_card: string | null
    business_license: string | null
    open_time: string | null
    close_time: string | null
    lat: number | null
    lng: number | null
}

export type RestaurantStats = {
    total: number
    active: number
    pending: number
}

export type RestaurantsPage = {
    restaurants: Restaurant[]
    total: number
    pageSize: number
}

export type PendingRestaurant = {
    id: string
    name: string
    category: string
    address: string
    phone: string
    email: string
    createdAt: Date | null
    owner_name: string | null
    line_id: string | null
    bank_name: string | null
    account_name: string | null
    account_no: string | null
    id_card: string | null
    business_license: string | null
    open_time: string | null
    close_time: string | null
    lat: number | null
    lng: number | null
}

export async function getPendingRestaurants(): Promise<PendingRestaurant[]> {
    const [rows]: any = await pool.query(`
        SELECT
            id, name, category,
            COALESCE(address, '') AS address,
            COALESCE(phone,   '') AS phone,
            COALESCE(email,   '') AS email,
            createdAt,
            owner_name, line_id,
            bank_name, account_name, account_no,
            id_card, business_license,
            open_time, close_time,
            lat, lng
        FROM Restaurant
        WHERE LOWER(status) = 'pending'
        ORDER BY createdAt ASC
    `)
    return rows
}

export async function getRestaurantStats(): Promise<RestaurantStats> {
    const [[row]]: any = await pool.query(`
        SELECT
            COUNT(*)                                                          AS total,
            SUM(CASE WHEN LOWER(status) = 'active'  THEN 1 ELSE 0 END)      AS active,
            SUM(CASE WHEN LOWER(status) = 'pending' THEN 1 ELSE 0 END)      AS pending
        FROM Restaurant
    `)
    return {
        total:   Number(row.total),
        active:  Number(row.active),
        pending: Number(row.pending),
    }
}

export async function getRestaurantCategories(): Promise<string[]> {
    const [rows]: any = await pool.query(`
        SELECT DISTINCT category
        FROM Restaurant
        WHERE category IS NOT NULL AND category != ''
        ORDER BY category ASC
    `)
    return rows.map((r: any) => r.category)
}

export async function getAllRestaurants(params: {
    status?:   string
    category?: string
    search?:   string
    page?:     number
} = {}): Promise<RestaurantsPage> {
    const { status, category, search, page = 1 } = params
    const offset = (page - 1) * PAGE_SIZE
    const values: (string | number)[] = []
    const conditions: string[] = ['1=1']

    if (status && status !== 'ALL') {
        conditions.push('LOWER(r.status) = ?')
        values.push(status.toLowerCase())
    }
    if (category && category !== 'ALL') {
        conditions.push('r.category = ?')
        values.push(category)
    }
    if (search && search.trim() !== '') {
        conditions.push('r.name LIKE ?')
        values.push(`%${search.trim()}%`)
    }

    const where = `WHERE ${conditions.join(' AND ')}`

    const [[countRow]]: any = await pool.query(
        `SELECT COUNT(*) AS total FROM Restaurant r ${where}`,
        values
    )

    const [rows]: any = await pool.query(
        `SELECT
           r.id,
           r.name,
           r.category,
           COALESCE(r.rating, 0)      AS rating,
           COALESCE(r.totalOrders, 0) AS totalOrders,
           r.status,
           r.imageUrl,
           r.address,
           COALESCE(r.phone, '')      AS phone,
           COALESCE(r.email, '')      AS email,
           r.owner_name, r.line_id,
           r.bank_name, r.account_name, r.account_no,
           r.id_card, r.business_license,
           r.open_time, r.close_time,
           r.lat, r.lng
         FROM Restaurant r
         ${where}
         ORDER BY r.totalOrders DESC, r.name ASC
         LIMIT ? OFFSET ?`,
        [...values, PAGE_SIZE, offset]
    )

    return { restaurants: rows, total: Number(countRow.total), pageSize: PAGE_SIZE }
}
