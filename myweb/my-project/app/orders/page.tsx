import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Link from 'next/link'
import Navbar from '../component/navbar'
import { getOrder, getAllOrders } from '@/app/lib/order'
import OrderFilters from './OrderFilters'
import AutoRefresh from '../component/AutoRefresh'

function formatCurrency(amount: number): string {
    return `$${Number(amount).toFixed(2)}`
}

function formatTime(date: Date): string {
    return new Intl.DateTimeFormat('en-US', {
        hour: 'numeric',
        minute: '2-digit',
        hour12: true,
    }).format(new Date(date))
}

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

export default async function Orders({
    searchParams,
}: {
    searchParams: Promise<{ status?: string; zone?: string; page?: string }>
}) {
    const session = await verifySession()
    if (!session) redirect('/login')

    const { status, zone, page } = await searchParams

    const currentStatus = status ?? 'ALL'
    const currentZone   = zone   ?? 'ALL'
    const currentPage   = Math.max(1, Number(page ?? 1))

    const [stats, { orders, total, pageSize }] = await Promise.all([
        getOrder(),
        getAllOrders({ status: currentStatus, zone: currentZone, page: currentPage }),
    ])

    const totalNum  = Number(total)
    const totalPages = Math.ceil(totalNum / pageSize)
    const from = totalNum === 0 ? 0 : (currentPage - 1) * pageSize + 1
    const to   = Math.min(currentPage * pageSize, totalNum)

    function buildHref(overrides: Record<string, string>) {
        const p = new URLSearchParams({
            status: currentStatus,
            zone:   currentZone,
            page:   String(currentPage),
            ...overrides,
        })
        return `?${p.toString()}`
    }

    return (
        <>
            <AutoRefresh interval={15_000} />
            <Navbar />

            <main className="pt-20 md:pt-24 pb-20 md:pb-8 px-4 md:px-8 md:ml-64 min-h-screen">

                {/* Page Header */}
                <div className="mb-6 flex flex-col sm:flex-row sm:items-end justify-between gap-4">
                    <div>
                        <h2 className="text-headline-lg text-on-background">Live Order Management</h2>
                        <p className="text-body-sm text-on-surface-variant mt-1">Monitor and manage active deliveries across all zones.</p>
                    </div>
                </div>

                {/* Stats Grid */}
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
                    <div className="bg-surface-container-lowest p-5 rounded-xl shadow-sm border border-surface-container-highest flex flex-col justify-between">
                        <div className="flex items-start justify-between mb-2">
                            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">Total Active</span>
                            <span className="material-symbols-outlined text-primary-container p-1.5 bg-surface-container-low rounded-lg">shopping_bag</span>
                        </div>
                        <div className="flex items-end gap-2">
                            <span className="text-headline-xl text-on-background">{stats.totalActive}</span>
                            <span className={`text-body-sm mb-1 flex items-center ${stats.changePercent >= 0 ? 'text-tertiary-container' : 'text-error'}`}>
                                <span className="material-symbols-outlined text-sm">{stats.changePercent >= 0 ? 'arrow_upward' : 'arrow_downward'}</span>
                                {Math.abs(stats.changePercent)}%
                            </span>
                        </div>
                    </div>

                    <div className="bg-surface-container-lowest p-5 rounded-xl shadow-sm border border-surface-container-highest flex flex-col justify-between">
                        <div className="flex items-start justify-between mb-2">
                            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">Preparing</span>
                            <span className="material-symbols-outlined text-tertiary p-1.5 bg-surface-container-low rounded-lg">soup_kitchen</span>
                        </div>
                        <div className="flex items-end gap-2">
                            <span className="text-headline-xl text-on-background">{stats.preparing}</span>
                        </div>
                    </div>

                    <div className="bg-surface-container-lowest p-5 rounded-xl shadow-sm border border-surface-container-highest flex flex-col justify-between">
                        <div className="flex items-start justify-between mb-2">
                            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">Out for Delivery</span>
                            <span className="material-symbols-outlined text-primary-container p-1.5 bg-surface-container-low rounded-lg">two_wheeler</span>
                        </div>
                        <div className="flex items-end gap-2">
                            <span className="text-headline-xl text-on-background">{stats.outForDelivery}</span>
                        </div>
                    </div>

                    <div className="bg-surface-container-lowest p-5 rounded-xl shadow-sm border border-surface-container-highest border-l-4 border-l-error flex flex-col justify-between relative overflow-hidden">
                        <div className="absolute -right-4 -top-4 w-16 h-16 bg-error/10 rounded-full blur-xl" />
                        <div className="flex items-start justify-between mb-2 relative z-10">
                            <span className="text-label-md text-error uppercase tracking-wider">Delayed</span>
                            <span className="material-symbols-outlined text-error p-1.5 bg-error-container rounded-lg">warning</span>
                        </div>
                        <div className="flex items-end gap-2 relative z-10">
                            <span className="text-headline-xl text-error">{stats.delayed}</span>
                            <span className="text-body-sm text-on-surface-variant mb-1">Requires attention</span>
                        </div>
                    </div>
                </div>

                {/* Table Card */}
                <div className="bg-surface-container-lowest rounded-3xl shadow-sm border border-surface-container-highest overflow-hidden">

                    {/* Filters */}
                    <Suspense fallback={<div className="p-4 h-18.25" />}>
                        <OrderFilters currentStatus={currentStatus} currentZone={currentZone} />
                    </Suspense>

                    {/* Table */}
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse min-w-225">
                            <thead>
                                <tr className="bg-surface-container text-on-surface-variant text-label-md uppercase tracking-wider border-b border-surface-container-highest">
                                    <th className="p-4 font-semibold">Order Details</th>
                                    <th className="p-4 font-semibold">Restaurant</th>
                                    <th className="p-4 font-semibold">Customer</th>
                                    <th className="p-4 font-semibold">Rider</th>
                                    <th className="p-4 font-semibold">Status</th>
                                    <th className="p-4 font-semibold text-right">Value</th>
                                    <th className="p-4 font-semibold text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-surface-container-highest text-body-sm text-on-surface">
                                {orders.length === 0 ? (
                                    <tr>
                                        <td colSpan={7} className="p-12 text-center text-on-surface-variant text-body-md">
                                            No orders found.
                                        </td>
                                    </tr>
                                ) : (
                                    orders.map(order => (
                                        <tr
                                            key={order.orderNumber}
                                            className={`hover:bg-surface-container/50 transition-colors ${order.status === 'DELAYED' ? 'bg-error-container/20 hover:bg-error-container/30' : ''}`}
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
                                                    <button className="text-primary-container hover:bg-surface-container-high p-2 rounded-full transition-colors" title="View Details">
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
                        </table>
                    </div>

                    {/* Pagination */}
                    <div className="p-4 border-t border-surface-container-highest flex items-center justify-between text-body-sm text-on-surface-variant bg-surface-container-lowest">
                        <span>Showing {from} to {to} of {totalNum} entries</span>
                        <div className="flex gap-1 items-center">
                            <Link
                                href={buildHref({ page: String(currentPage - 1) })}
                                aria-disabled={currentPage <= 1}
                                className={`p-1 rounded hover:bg-surface-container ${currentPage <= 1 ? 'pointer-events-none opacity-40' : ''}`}
                            >
                                <span className="material-symbols-outlined text-sm">chevron_left</span>
                            </Link>

                            {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                                let p: number
                                if (totalPages <= 5) {
                                    p = i + 1
                                } else if (currentPage <= 3) {
                                    p = i + 1
                                } else if (currentPage >= totalPages - 2) {
                                    p = totalPages - 4 + i
                                } else {
                                    p = currentPage - 2 + i
                                }
                                return (
                                    <Link
                                        key={p}
                                        href={buildHref({ page: String(p) })}
                                        className={`w-7 h-7 rounded flex items-center justify-center font-medium text-sm ${
                                            p === currentPage
                                                ? 'bg-primary-container text-on-primary'
                                                : 'hover:bg-surface-container'
                                        }`}
                                    >
                                        {p}
                                    </Link>
                                )
                            })}

                            {totalPages > 5 && currentPage < totalPages - 2 && (
                                <span className="w-7 h-7 flex items-center justify-center text-on-surface-variant">...</span>
                            )}

                            <Link
                                href={buildHref({ page: String(currentPage + 1) })}
                                aria-disabled={currentPage >= totalPages}
                                className={`p-1 rounded hover:bg-surface-container ${currentPage >= totalPages ? 'pointer-events-none opacity-40' : ''}`}
                            >
                                <span className="material-symbols-outlined text-sm">chevron_right</span>
                            </Link>
                        </div>
                    </div>
                </div>

            </main>
        </>
    )
}
