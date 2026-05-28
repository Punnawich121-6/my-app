'use client'
import { useEffect, useState } from 'react'
import { createPortal } from 'react-dom'
import type { OrderDetail } from '@/app/lib/order'

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

function statusBadge(status: string) {
    const map: Record<string, string> = {
        preparing:  'bg-surface-container text-on-surface-variant',
        ready:      'bg-blue-50 text-blue-700',
        delivering: 'bg-cyan-50 text-cyan-700',
        delayed:    'bg-red-50 text-red-700',
        pending:    'bg-amber-50 text-amber-700',
        accepted:   'bg-blue-50 text-blue-700',
        completed:  'bg-green-50 text-green-700',
        cancelled:  'bg-surface-container text-on-surface-variant',
    }
    return map[status.toLowerCase()] ?? 'bg-surface-container text-on-surface-variant'
}

export default function OrderDetailModal({
    orderId,
    onClose,
}: {
    orderId: string
    onClose: () => void
}) {
    const [detail, setDetail] = useState<OrderDetail | null>(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        fetch(`/api/orders/${orderId}`)
            .then(r => r.json())
            .then(data => { setDetail(data); setLoading(false) })
            .catch(() => setLoading(false))
    }, [orderId])

    const subtotal = detail ? Number(detail.totalAmount) - Number(detail.serviceFee) : 0

    const modal = (
        /* Backdrop */
        <div
            className="fixed inset-0 z-9999 bg-black/50 backdrop-blur-sm"
            onClick={e => { if (e.target === e.currentTarget) onClose() }}
        >
            {/* Modal box — centered via absolute */}
            <div
                className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2
                           bg-surface-container-lowest rounded-2xl shadow-2xl border border-outline-variant
                           w-130 max-w-[calc(100vw-32px)] max-h-[85vh] flex flex-col"
                onClick={e => e.stopPropagation()}
            >
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container shrink-0">
                    <div>
                        <h2 className="text-lg font-semibold text-on-surface">Order Details</h2>
                        {detail && <p className="text-sm text-on-surface-variant mt-0.5">#{detail.orderNumber}</p>}
                    </div>
                    <button
                        onClick={onClose}
                        className="p-1.5 rounded-full hover:bg-surface-container transition-colors text-on-surface-variant"
                    >
                        <span className="material-symbols-outlined text-xl">close</span>
                    </button>
                </div>

                {/* Body (scrollable) */}
                <div className="overflow-y-auto flex-1">
                    {loading ? (
                        <div className="flex justify-center items-center py-16">
                            <span className="material-symbols-outlined animate-spin text-orange-400 text-4xl">progress_activity</span>
                        </div>
                    ) : !detail ? (
                        <div className="py-16 text-center text-on-surface-variant">Failed to load order.</div>
                    ) : (
                        <div className="px-6 py-5 space-y-4">

                            {/* Status + Time */}
                            <div className="flex items-center justify-between">
                                <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${statusBadge(detail.status)}`}>
                                    {STATUS_LABEL[detail.status] ?? detail.status}
                                </span>
                                <span className="text-sm text-on-surface-variant">
                                    {new Intl.DateTimeFormat('en-US', {
                                        month: 'short', day: 'numeric',
                                        hour: 'numeric', minute: '2-digit', hour12: true,
                                    }).format(new Date(detail.createdAt))}
                                </span>
                            </div>

                            {/* Restaurant */}
                            <div className="bg-surface-container rounded-xl p-4">
                                <p className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider mb-1">Restaurant</p>
                                <p className="font-medium text-on-surface">{detail.restaurantName}</p>
                                {detail.restaurantAddress && (
                                    <p className="text-sm text-on-surface-variant mt-0.5">{detail.restaurantAddress}</p>
                                )}
                            </div>

                            {/* Customer */}
                            <div className="bg-surface-container rounded-xl p-4">
                                <p className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider mb-2">Customer</p>
                                <div className="flex items-center gap-2 mb-2">
                                    <div className="w-7 h-7 rounded-full bg-orange-100 text-orange-600 flex items-center justify-center font-bold text-xs shrink-0">
                                        {detail.customerName.charAt(0).toUpperCase()}
                                    </div>
                                    <p className="font-medium text-on-surface">{detail.customerName}</p>
                                </div>
                                {detail.customerPhone && (
                                    <p className="text-sm text-on-surface-variant flex items-center gap-1">
                                        <span className="material-symbols-outlined text-base">phone</span>
                                        {detail.customerPhone}
                                    </p>
                                )}
                                {detail.customerAddress && (
                                    <p className="text-sm text-on-surface-variant flex items-center gap-1 mt-1">
                                        <span className="material-symbols-outlined text-base">location_on</span>
                                        {detail.customerAddress}
                                    </p>
                                )}
                            </div>

                            {/* Rider */}
                            {detail.riderName && (
                                <div className="bg-surface-container rounded-xl p-4">
                                    <p className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider mb-1">Rider</p>
                                    <p className="font-medium text-on-surface flex items-center gap-1.5">
                                        <span className="material-symbols-outlined text-base text-cyan-500">two_wheeler</span>
                                        {detail.riderName}
                                    </p>
                                </div>
                            )}

                            {/* Items */}
                            <div>
                                <p className="text-xs font-semibold text-on-surface-variant uppercase tracking-wider mb-2">Items</p>
                                <div className="border border-outline-variant rounded-xl overflow-hidden divide-y divide-surface-container">
                                    {detail.items.map((item, i) => (
                                        <div key={i} className="flex items-center justify-between px-4 py-3 bg-surface-container-lowest">
                                            <div className="flex items-center gap-2.5">
                                                <span className="w-6 h-6 rounded-full bg-orange-50 text-orange-500 flex items-center justify-center text-xs font-bold shrink-0">
                                                    {item.quantity}
                                                </span>
                                                <span className="text-sm text-on-surface">{item.name}</span>
                                            </div>
                                            <span className="text-sm font-medium text-on-surface">
                                                ${(item.price * item.quantity).toFixed(2)}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            </div>

                            {/* Totals */}
                            <div className="bg-surface-container rounded-xl p-4 space-y-2">
                                <div className="flex justify-between text-sm text-on-surface-variant">
                                    <span>Subtotal</span>
                                    <span>${subtotal.toFixed(2)}</span>
                                </div>
                                <div className="flex justify-between text-sm text-on-surface-variant">
                                    <span>Delivery fee</span>
                                    <span>${Number(detail.serviceFee).toFixed(2)}</span>
                                </div>
                                <div className="flex justify-between font-semibold text-on-surface border-t border-outline-variant pt-2">
                                    <span>Total</span>
                                    <span>${Number(detail.totalAmount).toFixed(2)}</span>
                                </div>
                            </div>

                            {/* Notes */}
                            {detail.notes && (
                                <div className="bg-amber-50 rounded-xl p-4">
                                    <p className="text-xs font-semibold text-amber-500 uppercase tracking-wider mb-1">Notes</p>
                                    <p className="text-sm text-amber-900">{detail.notes}</p>
                                </div>
                            )}

                            <div className="pb-1" />
                        </div>
                    )}
                </div>
            </div>
        </div>
    )

    return createPortal(modal, document.body)
}
