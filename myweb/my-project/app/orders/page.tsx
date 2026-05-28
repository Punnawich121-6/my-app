import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Link from 'next/link'
import Navbar from '../component/navbar'
import { getOrder, getAllOrders } from '@/app/lib/order'
import OrderFilters from './OrderFilters'
import AutoRefresh from '../component/AutoRefresh'
import OrdersTableClient from './OrdersTableClient'

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
            <AutoRefresh interval={60_000} />
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
                            <OrdersTableClient orders={orders} />
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
