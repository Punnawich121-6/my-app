import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Link from 'next/link'
import Navbar from '../component/navbar'
import AutoRefresh from '../component/AutoRefresh'
import {
    getRestaurantStats,
    getRestaurantCategories,
    getAllRestaurants,
    getPendingRestaurants,
} from '@/app/lib/restaurant'
import RestaurantFilters from './RestaurantFilters'
import AddRestaurantModal from './AddRestaurantModal'
import EditRestaurantModal from './EditRestaurantModal'
import PendingApprovals from './PendingApprovals'

const STATUS_LABEL: Record<string, string> = {
    active:   'Active',
    pending:  'Pending',
    inactive: 'Inactive',
}

const STATUS_STYLE: Record<string, string> = {
    active:   'bg-green-50 text-green-700 border-green-200',
    pending:  'bg-amber-50 text-amber-700 border-amber-200',
    inactive: 'bg-surface-container text-on-surface-variant border-outline-variant',
}

const STATUS_DOT: Record<string, string> = {
    active:   'bg-green-500',
    pending:  'bg-amber-500',
    inactive: 'bg-on-surface-variant/40',
}

export default async function Restaurants({
    searchParams,
}: {
    searchParams: Promise<{ status?: string; category?: string; search?: string; page?: string }>
}) {
    const session = await verifySession()
    if (!session) redirect('/login')

    const { status, category, search, page } = await searchParams

    const currentStatus   = status   ?? 'ALL'
    const currentCategory = category ?? 'ALL'
    const currentSearch   = search   ?? ''
    const currentPage     = Math.max(1, Number(page ?? 1))

    const [stats, categories, pendingRestaurants, { restaurants, total, pageSize }] = await Promise.all([
        getRestaurantStats(),
        getRestaurantCategories(),
        getPendingRestaurants(),
        getAllRestaurants({
            status:   currentStatus,
            category: currentCategory,
            search:   currentSearch,
            page:     currentPage,
        }),
    ])

    const totalPages = Math.ceil(total / pageSize)
    const from = total === 0 ? 0 : (currentPage - 1) * pageSize + 1
    const to   = Math.min(currentPage * pageSize, total)

    function buildHref(overrides: Record<string, string>) {
        const p = new URLSearchParams({
            status:   currentStatus,
            category: currentCategory,
            search:   currentSearch,
            page:     String(currentPage),
            ...overrides,
        })
        return `?${p.toString()}`
    }

    return (
        <>
            <AutoRefresh interval={30_000} />
            <Navbar />

            <main className="md:ml-64 pt-16 px-4 md:px-8 pb-12 min-h-screen">

                {/* Page Header */}
                <div className="flex justify-between items-center mt-8 mb-8 gap-4 flex-wrap">
                    <div>
                        <h2 className="text-headline-lg text-on-background">Restaurant Management</h2>
                        <p className="text-body-md text-on-surface-variant mt-1">Manage partners, view status, and onboard new vendors.</p>
                    </div>
                    <AddRestaurantModal />
                </div>

                {/* Pending Approvals */}
                <PendingApprovals restaurants={pendingRestaurants} />

                {/* Summary Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    <div className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-container flex items-center gap-4">
                        <div className="w-12 h-12 rounded-full bg-primary-container/10 flex items-center justify-center text-primary-container">
                            <span className="material-symbols-outlined text-2xl">storefront</span>
                        </div>
                        <div>
                            <p className="text-label-md text-on-surface-variant">Total Restaurants</p>
                            <p className="text-headline-md text-on-background">{stats.total.toLocaleString()}</p>
                        </div>
                    </div>
                    <div className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-container flex items-center gap-4">
                        <div className="w-12 h-12 rounded-full bg-green-500/10 flex items-center justify-center text-green-600">
                            <span className="material-symbols-outlined text-2xl">check_circle</span>
                        </div>
                        <div>
                            <p className="text-label-md text-on-surface-variant">Active Now</p>
                            <p className="text-headline-md text-on-background">{stats.active.toLocaleString()}</p>
                        </div>
                    </div>
                    <div className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-container flex items-center gap-4">
                        <div className="w-12 h-12 rounded-full bg-amber-500/10 flex items-center justify-center text-amber-600">
                            <span className="material-symbols-outlined text-2xl">pending</span>
                        </div>
                        <div>
                            <p className="text-label-md text-on-surface-variant">Pending Approval</p>
                            <p className="text-headline-md text-on-background">{stats.pending.toLocaleString()}</p>
                        </div>
                    </div>
                </div>

                {/* Table Card */}
                <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-surface-container flex flex-col">

                    {/* Filters */}
                    <Suspense fallback={<div className="p-4 h-18 border-b border-surface-container bg-surface-bright rounded-t-xl" />}>
                        <RestaurantFilters
                            currentStatus={currentStatus}
                            currentCategory={currentCategory}
                            currentSearch={currentSearch}
                            categories={categories}
                        />
                    </Suspense>

                    {/* Table */}
                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse min-w-180">
                            <thead>
                                <tr className="border-b border-surface-container bg-surface-bright">
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Restaurant Name</th>
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Category</th>
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Rating</th>
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Total Orders</th>
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Status</th>
                                    <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">Actions</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-surface-container">
                                {restaurants.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} className="py-12 text-center text-on-surface-variant text-body-md">
                                            No restaurants found.
                                        </td>
                                    </tr>
                                ) : (
                                    restaurants.map(r => {
                                        const s = r.status.toLowerCase()
                                        const isInactive = s === 'inactive'
                                        return (
                                            <tr key={r.id} className="hover:bg-surface-bright transition-colors">
                                                <td className="py-4 px-6">
                                                    <div className="flex items-center gap-4">
                                                        {r.imageUrl ? (
                                                            // eslint-disable-next-line @next/next/no-img-element
                                                            <img
                                                                alt={r.name}
                                                                src={r.imageUrl}
                                                                className={`w-10 h-10 rounded-lg object-cover border border-surface-container ${isInactive ? 'opacity-60' : ''}`}
                                                            />
                                                        ) : (
                                                            <div className={`w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center text-on-surface-variant font-bold text-sm shrink-0 ${isInactive ? 'opacity-60' : ''}`}>
                                                                {r.name.charAt(0).toUpperCase()}
                                                            </div>
                                                        )}
                                                        <div>
                                                            <span className={`text-label-lg text-on-background ${isInactive ? 'opacity-70' : ''}`}>{r.name}</span>
                                                            {r.address && (
                                                                <p className="text-xs text-on-surface-variant mt-0.5 truncate max-w-48">{r.address}</p>
                                                            )}
                                                        </div>
                                                    </div>
                                                </td>
                                                <td className="py-4 px-6">
                                                    <span className="inline-block bg-surface-container px-3 py-1 rounded-full text-label-sm text-on-surface-variant">{r.category || '—'}</span>
                                                </td>
                                                <td className="py-4 px-6 text-body-md text-on-surface">
                                                    <div className="flex items-center gap-1">
                                                        <span className="material-symbols-outlined text-amber-500 text-[18px]" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                                                        {Number(r.rating) > 0 ? Number(r.rating).toFixed(1) : '—'}
                                                    </div>
                                                </td>
                                                <td className="py-4 px-6 text-body-md text-on-surface">
                                                    {Number(r.totalOrders).toLocaleString()}
                                                </td>
                                                <td className="py-4 px-6">
                                                    <span className={`inline-flex items-center gap-1 text-label-md px-2.5 py-1 rounded-full border ${STATUS_STYLE[s] ?? 'bg-surface-variant text-on-surface-variant border-outline-variant'}`}>
                                                        <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[s] ?? 'bg-surface-variant'}`} />
                                                        {STATUS_LABEL[s] ?? r.status}
                                                    </span>
                                                </td>
                                                <td className="py-4 px-6 text-right">
                                                    <EditRestaurantModal restaurant={{
                                                        id:               r.id,
                                                        name:             r.name,
                                                        category:         r.category,
                                                        address:          r.address,
                                                        phone:            r.phone,
                                                        email:            r.email,
                                                        status:           r.status,
                                                        owner_name:       r.owner_name,
                                                        line_id:          r.line_id,
                                                        bank_name:        r.bank_name,
                                                        account_name:     r.account_name,
                                                        account_no:       r.account_no,
                                                        id_card:          r.id_card,
                                                        business_license: r.business_license,
                                                        open_time:        r.open_time,
                                                        close_time:       r.close_time,
                                                        lat:              r.lat,
                                                        lng:              r.lng,
                                                        imageUrl:         r.imageUrl ?? null,
                                                    }} />
                                                </td>
                                            </tr>
                                        )
                                    })
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* Pagination */}
                    <div className="p-4 border-t border-surface-container flex items-center justify-between bg-surface-bright rounded-b-xl flex-wrap gap-3">
                        <p className="text-body-sm text-on-surface-variant">Showing {from} to {to} of {total.toLocaleString()} entries</p>
                        <div className="flex items-center gap-1">
                            <Link
                                href={buildHref({ page: String(currentPage - 1) })}
                                aria-disabled={currentPage <= 1}
                                className={`p-2 rounded-lg border border-outline-variant text-on-surface-variant hover:bg-surface-container transition-colors ${currentPage <= 1 ? 'pointer-events-none opacity-40' : ''}`}
                            >
                                <span className="material-symbols-outlined text-[20px]">chevron_left</span>
                            </Link>

                            {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                                let p: number
                                if (totalPages <= 5)           p = i + 1
                                else if (currentPage <= 3)     p = i + 1
                                else if (currentPage >= totalPages - 2) p = totalPages - 4 + i
                                else                           p = currentPage - 2 + i
                                return (
                                    <Link
                                        key={p}
                                        href={buildHref({ page: String(p) })}
                                        className={`w-8 h-8 rounded-lg text-label-md flex items-center justify-center transition-colors ${
                                            p === currentPage
                                                ? 'bg-primary-container text-on-primary'
                                                : 'border border-outline-variant text-on-surface hover:bg-surface-container'
                                        }`}
                                    >
                                        {p}
                                    </Link>
                                )
                            })}

                            {totalPages > 5 && currentPage < totalPages - 2 && (
                                <span className="text-on-surface-variant px-1">...</span>
                            )}

                            <Link
                                href={buildHref({ page: String(currentPage + 1) })}
                                aria-disabled={currentPage >= totalPages}
                                className={`p-2 rounded-lg border border-outline-variant text-on-surface hover:bg-surface-container transition-colors ${currentPage >= totalPages ? 'pointer-events-none opacity-40' : ''}`}
                            >
                                <span className="material-symbols-outlined text-[20px]">chevron_right</span>
                            </Link>
                        </div>
                    </div>

                </div>

            </main>
        </>
    )
}
