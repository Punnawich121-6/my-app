import { io, Socket } from 'socket.io-client'

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL ?? 'http://localhost:3001'

let socket: Socket | null = null
let consumers = 0

export function getAdminSocket(): Socket {
  if (!socket) {
    socket = io(BACKEND_URL, {
      transports: ['websocket'],
      autoConnect: false,
    })
  }
  if (!socket.connected) {
    socket.connect()
  }
  return socket
}

/** Call in useEffect — increments consumer count and joins admin room. */
export function mountAdminSocket(): Socket {
  const s = getAdminSocket()
  if (consumers === 0) {
    s.emit('join_admin')
  }
  consumers++
  return s
}

/** Call in useEffect cleanup — decrements consumer count; disconnects only when no consumers remain. */
export function unmountAdminSocket() {
  consumers = Math.max(0, consumers - 1)
  if (consumers === 0 && socket) {
    socket.emit('leave_admin')
    socket.disconnect()
    socket = null
  }
}
