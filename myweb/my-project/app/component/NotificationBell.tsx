'use client'
import { useState, useEffect, useRef, useCallback } from 'react'
import Link from 'next/link'
import { mountAdminSocket, unmountAdminSocket } from '@/app/lib/socket'

type Notif = {
    id: string
    type: 'alert' | 'restaurant' | 'order' | 'support'
    title: string
    body: string
    href: string
    time: string
    unreadCount?: number
}

const TYPE_ICON: Record<string, string> = {
    alert:      'warning',
    restaurant: 'restaurant',
    order:      'receipt_long',
    support:    'support_agent',
}
const TYPE_COLOR: Record<string, string> = {
    alert:      'text-red-500',
    restaurant: 'text-blue-500',
    order:      'text-orange-500',
    support:    'text-orange-400',
}

const POLL_MS = 10_000

export default function NotificationBell() {
    const [notifications, setNotifications] = useState<Notif[]>([])
    const [readIds, setReadIds]             = useState<Set<string>>(new Set())
    const [open, setOpen]                   = useState(false)
    const wrapRef                           = useRef<HTMLDivElement>(null)
    const prevIdsRef                        = useRef<Set<string>>(new Set())

    const fetchNotifs = useCallback(async () => {
        try {
            const res  = await fetch('/api/notifications')
            const data: Notif[] = await res.json()
            setNotifications(data)

            // detect brand-new support notifications → play subtle sound / flash
            const newIds = new Set(data.map(n => n.id))
            const brandNew = data.filter(
                n => n.type === 'support' && !prevIdsRef.current.has(n.id)
            )
            if (brandNew.length > 0 && prevIdsRef.current.size > 0) {
                // browser tab title flash
                const orig = document.title
                document.title = `🔔 ข้อความใหม่! — ${orig}`
                setTimeout(() => { document.title = orig }, 4000)
            }
            prevIdsRef.current = newIds
        } catch (e) {
            console.error('[NotificationBell] fetch failed:', e)
        }
    }, [])

    useEffect(() => {
        fetchNotifs()
        const id = setInterval(fetchNotifs, POLL_MS)

        const socket = mountAdminSocket()
        socket.on('new_order', fetchNotifs)
        socket.on('order_status_changed', fetchNotifs)

        return () => {
            clearInterval(id)
            socket.off('new_order', fetchNotifs)
            socket.off('order_status_changed', fetchNotifs)
            unmountAdminSocket()
        }
    }, [fetchNotifs])

    useEffect(() => {
        function onClickOutside(e: MouseEvent) {
            if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setOpen(false)
        }
        document.addEventListener('mousedown', onClickOutside)
        return () => document.removeEventListener('mousedown', onClickOutside)
    }, [])

    const unreadCount = notifications.filter(n => !readIds.has(n.id)).length

    function markAllRead() {
        setReadIds(new Set(notifications.map(n => n.id)))
    }

    function markOne(id: string) {
        setReadIds(prev => new Set([...prev, id]))
        setOpen(false)
    }

    return (
        <div ref={wrapRef} className="relative">
            <button
                onClick={() => setOpen(v => !v)}
                className="text-on-surface-variant hover:bg-surface-container rounded-full p-2 relative"
            >
                <span className="material-symbols-outlined">notifications</span>
                {unreadCount > 0 && (
                    <span className="absolute top-1.5 right-1.5 min-w-4.5 h-4.5 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-1">
                        {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                )}
            </button>

            {open && (
                <div className="absolute right-0 top-full mt-2 w-80 bg-surface-container-lowest rounded-2xl shadow-xl border border-surface-container-highest z-50 overflow-hidden">
                    {/* Header */}
                    <div className="flex items-center justify-between px-4 py-3 border-b border-surface-container">
                        <div className="flex items-center gap-2">
                            <h3 className="font-semibold text-on-surface text-sm">Notifications</h3>
                            {unreadCount > 0 && (
                                <span className="bg-red-100 text-red-600 text-xs font-bold px-1.5 py-0.5 rounded-full">
                                    {unreadCount}
                                </span>
                            )}
                        </div>
                        {unreadCount > 0 && (
                            <button onClick={markAllRead} className="text-xs text-orange-500 hover:underline">
                                Mark all read
                            </button>
                        )}
                    </div>

                    {/* List */}
                    <ul className="divide-y divide-surface-container max-h-90 overflow-y-auto">
                        {notifications.length === 0 ? (
                            <li className="px-4 py-8 text-center text-sm text-on-surface-variant">
                                <span className="material-symbols-outlined text-3xl block mb-2 text-on-surface-variant/40">notifications_off</span>
                                No notifications
                            </li>
                        ) : (
                            notifications.map(n => {
                                const read = readIds.has(n.id)
                                return (
                                    <li key={n.id} className={read ? '' : 'bg-orange-50/40'}>
                                        <Link
                                            href={n.href}
                                            onClick={() => markOne(n.id)}
                                            className="flex items-start gap-3 px-4 py-3 hover:bg-surface-container transition-colors"
                                        >
                                            <span className={`material-symbols-outlined text-[20px] mt-0.5 shrink-0 ${TYPE_COLOR[n.type]}`}>
                                                {TYPE_ICON[n.type]}
                                            </span>
                                            <div className="flex-1 min-w-0">
                                                <div className="flex items-center gap-2">
                                                    <p className="text-sm font-medium text-on-surface truncate">{n.title}</p>
                                                    {n.type === 'support' && n.unreadCount && n.unreadCount > 1 && (
                                                        <span className="shrink-0 bg-orange-500 text-white text-[10px] font-bold rounded-full px-1.5 py-0.5">
                                                            {n.unreadCount}
                                                        </span>
                                                    )}
                                                </div>
                                                <p className="text-xs text-on-surface-variant mt-0.5 truncate">{n.body}</p>
                                                <p className="text-xs text-on-surface-variant/60 mt-1">{n.time}</p>
                                            </div>
                                            {!read && <span className="w-2 h-2 bg-orange-400 rounded-full mt-2 shrink-0" />}
                                        </Link>
                                    </li>
                                )
                            })
                        )}
                    </ul>
                </div>
            )}
        </div>
    )
}
