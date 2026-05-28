'use client'
import { useState, useEffect } from 'react'
import type { AllOrder } from '@/app/lib/order'
import OrderDetailModal from './OrderDetailModal'
import { mountAdminSocket, unmountAdminSocket } from '@/app/lib/socket'

const STATUS_LABEL: Record<string, string> = {
    pending:    'Pending',
    accepted:   'Accepted',
    preparing:  'Preparing',
    ready:      'Ready',
    delivering: 'On the Way',
    completed:  'Delivered',
    cancelled:  'Cancelled',
    delayed:    'Delayed',
}

function getStatusStyle(status: string): string {
    switch (status.toLowerCase()) {
        case 'preparing':  return 'bg-surface-container text-on-surface border border-outline-variant'
        case 'ready':      return 'bg-blue-50 text-blue-700 border border-blue-200'
        case 'delivering': return 'bg-surface-container-low text-tertiary-container border border-tertiary-container/20'
        case 'delayed':    return 'bg-error-container text-on-error-container border border-error/20'
        case 'pending':    return 'bg-amber-50 text-amber-700 border border-amber-200'
        case 'accepted':   return 'bg-blue-50 text-blue-700 border border-blue-200'
        case 'completed':  return 'bg-green-50 text-green-700 border border-green-200'
        case 'cancelled':  return 'bg-surface-variant text-on-surface-variant border border-outline-variant'
        default:           return 'bg-surface-variant text-on-surface-variant'
    }
}

function formatTime(date: Date): string {
    return new Intl.DateTimeFormat('en-US', {
        hour: 'numeric', minute: '2-digit', hour12: true,
    }).format(new Date(date))
}

function formatCurrency(amount: number): string {
    return `$${Number(amount).toFixed(2)}`
}

export default function OrdersTableClient({ orders }: { orders: AllOrder[] }) {
    const [selectedId, setSelectedId]   = useState<string | null>(null)
    const [liveOrders, setLiveOrders]   = useState<AllOrder[]>(orders)
    const [flashedId, setFlashedId]     = useState<string | null>(null)

    useEffect(() => { setLiveOrders(orders) }, [orders])

    useEffect(() => {
        const socket = mountAdminSocket()
        socket.on('order_status_changed', ({ order_id, status }: { order_id: string; status: string }) => {
            setLiveOrders(prev =>
                prev.map(o => o.id === order_id ? { ...o, status } : o)
            )
            setFlashedId(order_id)
            setTimeout(() => setFlashedId(null), 2000)
        })
        return () => {
            socket.off('order_status_changed')
            unmountAdminSocket()
        }
    }, [])

    return (
        <>
            <tbody className="divide-y divide-surface-container-highest text-body-sm text-on-surface">
                {liveOrders.length === 0 ? (
                    <tr>
                        <td colSpan={7} className="p-12 text-center text-on-surface-variant text-body-md">
                            No orders found.
                        </td>
                    </tr>
                ) : (
                    liveOrders.map(order => (
                        <tr
                            key={order.orderNumber}
                            className={`hover:bg-surface-container/50 transition-colors ${
                                flashedId === order.id ? 'bg-primary-container/20' :
                                order.status === 'DELAYED' ? 'bg-error-container/20 hover:bg-error-container/30' : ''
                            }`}
                        >
                            <td className="p-4">
                                <div className="text-label-lg text-on-background">#{order.orderNumber}</div>
                                <div className={`text-xs mt-0.5 ${order.status === 'DELAYED' ? 'text-error font-medium' : 'text-on-surface-variant'}`}>
                                    {formatTime(order.createdAt)}
                                </div>
                            </td>
                            <td className="p-4">
                                <div className="font-medium">{order.restaurantName}</div>
                                {order.restaurantAddress && (
                                    <div className="text-on-surface-variant text-xs mt-0.5 truncate max-w-35">{order.restaurantAddress}</div>
                                )}
                            </td>
                            <td className="p-4">
                                <div className="flex items-center gap-2">
                                    <div className="w-6 h-6 rounded-full bg-secondary-container text-on-secondary-container flex items-center justify-center font-bold text-xs shrink-0">
                                        {order.customerName.charAt(0).toUpperCase()}
                                    </div>
                                    <span>{order.customerName}</span>
                                </div>
                            </td>
                            <td className="p-4">
                                {order.riderName ? (
                                    <span>{order.riderName}</span>
                                ) : (
                                    <button className="text-xs text-label-md text-primary-container border border-primary-container/30 px-2 py-1 rounded hover:bg-surface-container transition-colors">
                                        Assign Rider
                                    </button>
                                )}
                            </td>
                            <td className="p-4">
                                <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-label-md ${getStatusStyle(order.status)}`}>
                                    {order.status === 'delayed' && (
                                        <span className="w-1.5 h-1.5 rounded-full bg-error animate-pulse" />
                                    )}
                                    {(order.status === 'delivering' || order.status === 'ready') && (
                                        <span className="w-1.5 h-1.5 rounded-full bg-tertiary-container" />
                                    )}
                                    {order.status === 'preparing' && (
                                        <span className="material-symbols-outlined text-[14px]">skillet</span>
                                    )}
                                    {order.status === 'completed' && (
                                        <span className="material-symbols-outlined text-[14px]">check_circle</span>
                                    )}
                                    {order.status === 'cancelled' && (
                                        <span className="material-symbols-outlined text-[14px]">cancel</span>
                                    )}
                                    {STATUS_LABEL[order.status] ?? order.status}
                                </span>
                            </td>
                            <td className="p-4 text-right text-label-lg">
                                {formatCurrency(order.totalAmount)}
                            </td>
                            <td className="p-4 text-center">
                                <div className="flex justify-center gap-1">
                                    <button
                                        onClick={() => setSelectedId(order.id)}
                                        className="text-primary-container hover:bg-surface-container-high p-2 rounded-full transition-colors"
                                        title="View Details"
                                    >
                                        <span className="material-symbols-outlined text-[20px]">visibility</span>
                                    </button>
                                    {order.status === 'delayed' && (
                                        <button className="text-error hover:bg-error-container p-2 rounded-full transition-colors" title="Contact Support">
                                            <span className="material-symbols-outlined text-[20px]">support_agent</span>
                                        </button>
                                    )}
                                </div>
                            </td>
                        </tr>
                    ))
                )}
            </tbody>

            {selectedId && (
                <OrderDetailModal
                    orderId={selectedId}
                    onClose={() => setSelectedId(null)}
                />
            )}
        </>
    )
}
