import 'server-only'
import { SignJWT, jwtVerify } from 'jose'
import { cookies } from 'next/headers'



// read value from .env.local โดยเเปลง  String -> bytes เพราะ ใช้ jose  ต้องการ  key แบบ bytes
function getKey() {
  return new TextEncoder().encode(process.env.SESSION_SECRET!)
}

// define funtion encrypt 
export async function encrypt(paylaod: { userId: string ; expiresAt: Date}) { 
    return new SignJWT(paylaod)
    .setProtectedHeader({ alg: 'HS256' }) // user HS256 algorithm for signing the JWT
    .setIssuedAt() // Timestamp of when the JWT was created
    .setExpirationTime('7d')  // set expire time 7 วัน
    .sign(getKey()) // sign the JWT with the secret key and return the token as a string
} 

// define function decrypt
export async function decrypt(token: string  | undefined){
    if (!token) {
        return null
    }
    try {
        const {payload} = await jwtVerify(token, getKey(), {algorithms: ['HS256']})
        return payload as { userId: string; expireAT: Date}
    }
    catch {
        return null

    }
}
export async function createSession(userId: string) {
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 วัน
    const token = await encrypt({ userId, expiresAt })
    const cookieStore = await cookies()

    cookieStore.set('session', token, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        expires: expiresAt,
        path: '/',
    
    })
}

export async function deleteSession() {
    const cookieStore = await cookies()
    cookieStore.delete('session')
}