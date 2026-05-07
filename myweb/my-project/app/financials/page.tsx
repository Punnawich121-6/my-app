import Link from 'next/link'
import Navbar from '../component/navbar'
import RevenueChartWrapper from '../component/RevenueChartWrapper'
import FinancialDonutChart from './FinancialDonutChart'
import {
    getFinancialStats,
    getRevenueBreakdown,
    getFinancialDailyRevenue,
    getTransactions,
} from '@/app/lib/financials'

function fmt(amount: number): string {
    if (amount >= 1_000_000) return `$${(amount / 1_000_000).toFixed(1)}M`
    if (amount >= 1_000)     return `$${(amount / 1_000).toFixed(1)}k`
    return `$${amount.toLocaleString()}`
}

function fmtFull(amount: number): string {
    return `$${Number(amount).toFixed(2)}`
}

function fmtDateTime(date: Date): string {
    return new Intl.DateTimeFormat('en-US', {
        month: 'short', day: 'numeric',
        hour: 'numeric', minute: '2-digit', hour12: true,
    }).format(new Date(date))
}

const TX_STATUS_STYLE: Record<string, string> = {
    completed: 'bg-tertiary-fixed text-on-tertiary-container',
    paid:      'bg-tertiary-fixed text-on-tertiary-container',
    pending:   'bg-surface-variant text-on-surface-variant',
    failed:    'bg-error-container text-on-error-container',
}

export default async function Financials({
    searchParams,
}: {
    searchParams: Promise<{ page?: string }>
}) {
    const { page } = await searchParams
    const currentPage = Math.max(1, Number(page ?? 1))

    const [stats, breakdown, dailyRevenue, { transactions, total, pageSize }] = await Promise.all([
        getFinancialStats(),
        getRevenueBreakdown(),
        getFinancialDailyRevenue(),
        getTransactions(currentPage),
    ])

    const totalPages = Math.ceil(total / pageSize)
    const from = total === 0 ? 0 : (currentPage - 1) * pageSize + 1
    const to   = Math.min(currentPage * pageSize, total)

    function pageHref(p: number) {
        return `?page=${p}`
    }

    const kpiCards = [
        {
            label:    'Total Revenue',
            value:    fmt(stats.thisMonthRevenue),
            sub:      'This month',
            change:   stats.revenueChangePercent,
            icon:     'attach_money',
            iconBg:   'bg-primary-fixed',
            iconText: 'text-on-primary-fixed',
        },
        {
            label:    'Platform Commission',
            value:    fmt(stats.totalCommission),
            sub:      '15% of monthly revenue',
            change:   null,
            icon:     'percent',
            iconBg:   'bg-tertiary-container',
            iconText: 'text-on-tertiary-container',
        },
        {
            label:    'Merchant Payouts',
            value:    fmt(stats.merchantPayouts),
            sub:      'Paid to restaurants',
            change:   null,
            icon:     'account_balance_wallet',
            iconBg:   'bg-surface-variant',
            iconText: 'text-on-surface-variant',
        },
        {
            label:    'Avg. Order Value',
            value:    fmt(stats.avgOrderValue),
            sub:      'Per completed order',
            change:   null,
            icon:     'shopping_cart',
            iconBg:   'bg-secondary-fixed',
            iconText: 'text-on-secondary-fixed',
        },
        {
            label:    'Service Fees Collected',
            value:    fmt(stats.totalServiceFees),
            sub:      'From all completed orders',
            change:   null,
            icon:     'receipt',
            iconBg:   'bg-primary-container',
            iconText: 'text-on-primary',
        },
        {
            label:    'Completed Orders',
            value:    stats.totalCompletedOrders.toLocaleString(),
            sub:      'All time',
            change:   null,
            icon:     'check_circle',
            iconBg:   'bg-tertiary-fixed',
            iconText: 'text-on-tertiary-container',
        },
    ]

    return (
        <>
            <Navbar />

            <main className="pt-24 pb-12 px-6 md:px-8 md:ml-64 max-w-7xl mx-auto">

                {/* Header */}
                <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
                    <div>
                        <h2 className="text-headline-md text-on-surface">Financial Overview</h2>
                        <p className="text-body-sm text-on-surface-variant mt-1">Track revenue, payouts, and overall platform health.</p>
                    </div>
                </div>

                {/* KPI Cards */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-6 mb-8">
                    {kpiCards.map((card, i) => (
                        <div key={i} className="col-span-1 xl:col-span-2 bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-variant relative overflow-hidden">
                            <div className="flex justify-between items-start mb-4">
                                <div className={`w-10 h-10 rounded-full ${card.iconBg} flex items-center justify-center ${card.iconText}`}>
                                    <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>{card.icon}</span>
                                </div>
                                {card.change !== null && (
                                    <span className={`text-label-sm flex items-center gap-1 py-1 px-2 rounded-full ${card.change >= 0 ? 'text-tertiary bg-tertiary-fixed' : 'text-error bg-error-container'}`}>
                                        <span className="material-symbols-outlined text-[12px]">{card.change >= 0 ? 'trending_up' : 'trending_down'}</span>
                                        {card.change >= 0 ? '+' : ''}{card.change}%
                                    </span>
                                )}
                            </div>
                            <p className="text-label-md text-on-surface-variant mb-1">{card.label}</p>
                            <h3 className="text-headline-lg text-on-surface">{card.value}</h3>
                            <p className="text-body-xs text-on-surface-variant mt-1">{card.sub}</p>
                        </div>
                    ))}
                </div>

                {/* Charts */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">

                    {/* Revenue Line Chart — 30 days */}
                    <div className="lg:col-span-2 bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-variant">
                        <div className="flex justify-between items-center mb-6">
                            <div>
                                <h3 className="text-headline-sm text-on-surface">Revenue Trends</h3>
                                <p className="text-body-sm text-on-surface-variant mt-0.5">Last 30 days — completed orders only</p>
                            </div>
                        </div>
                        <div className="h-72 w-full">
                            <RevenueChartWrapper data={dailyRevenue} />
                        </div>
                    </div>

                    {/* Revenue Split Donut */}
                    <div className="bg-surface-container-lowest rounded-xl p-6 shadow-sm border border-surface-variant">
                        <div className="flex justify-between items-center mb-4">
                            <h3 className="text-headline-sm text-on-surface">Revenue Split</h3>
                        </div>
                        <div className="h-64 w-full relative">
                            <FinancialDonutChart data={breakdown} />
                            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                                <span className="text-label-md text-on-surface-variant">Total</span>
                                <span className="text-headline-md text-on-surface">
                                    {fmt(breakdown.merchantPayouts + breakdown.platformCommission + breakdown.serviceFees)}
                                </span>
                            </div>
                        </div>

                        {/* Legend numbers */}
                        <div className="mt-4 space-y-2 border-t border-surface-variant pt-4">
                            {[
                                { label: 'Merchant Payouts',    value: breakdown.merchantPayouts,    color: 'bg-[#e9e1dc]' },
                                { label: 'Platform Commission', value: breakdown.platformCommission, color: 'bg-[#ff6b35]' },
                                { label: 'Service Fees',        value: breakdown.serviceFees,        color: 'bg-[#00a7cb]' },
                            ].map(item => (
                                <div key={item.label} className="flex items-center justify-between text-body-sm">
                                    <div className="flex items-center gap-2">
                                        <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${item.color}`} />
                                        <span className="text-on-surface-variant">{item.label}</span>
                                    </div>
                                    <span className="text-on-surface font-medium">{fmt(item.value)}</span>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>

                {/* Transactions Table */}
                <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-surface-variant overflow-hidden">
                    <div className="px-6 py-5 border-b border-surface-variant flex justify-between items-center bg-surface-container-low/50">
                        <div>
                            <h3 className="text-headline-sm text-on-surface">Transactions</h3>
                            <p className="text-body-sm text-on-surface-variant mt-0.5">All restaurant payouts</p>
                        </div>
                    </div>

                    <div className="overflow-x-auto">
                        <table className="w-full text-left border-collapse min-w-180">
                            <thead>
                                <tr className="bg-surface-container-low/30 border-b border-surface-variant text-on-surface-variant text-label-md">
                                    <th className="px-6 py-4 font-semibold">Transaction ID</th>
                                    <th className="px-6 py-4 font-semibold">Order</th>
                                    <th className="px-6 py-4 font-semibold">Restaurant</th>
                                    <th className="px-6 py-4 font-semibold">Customer</th>
                                    <th className="px-6 py-4 font-semibold">Payout</th>
                                    <th className="px-6 py-4 font-semibold">Service Fee</th>
                                    <th className="px-6 py-4 font-semibold">Date</th>
                                    <th className="px-6 py-4 font-semibold">Status</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-surface-variant">
                                {transactions.length === 0 ? (
                                    <tr>
                                        <td colSpan={8} className="px-6 py-12 text-center text-on-surface-variant text-body-md">
                                            No transactions yet.
                                        </td>
                                    </tr>
                                ) : (
                                    transactions.map(t => {
                                        const s = t.status.toLowerCase()
                                        return (
                                            <tr key={t.id} className="hover:bg-surface-container-lowest/50 transition-colors">
                                                <td className="px-6 py-4 text-body-sm text-on-surface font-mono">
                                                    {t.id.slice(0, 8).toUpperCase()}
                                                </td>
                                                <td className="px-6 py-4 text-body-sm text-on-surface">
                                                    #{t.orderNumber}
                                                </td>
                                                <td className="px-6 py-4 text-body-sm text-on-surface">{t.restaurantName}</td>
                                                <td className="px-6 py-4 text-body-sm text-on-surface-variant">{t.customerName ?? '—'}</td>
                                                <td className="px-6 py-4 text-label-md text-on-surface">{fmtFull(t.amount)}</td>
                                                <td className="px-6 py-4 text-body-sm text-on-surface-variant">{fmtFull(t.serviceFee)}</td>
                                                <td className="px-6 py-4 text-body-sm text-on-surface-variant whitespace-nowrap">
                                                    {fmtDateTime(t.createdAt)}
                                                </td>
                                                <td className="px-6 py-4">
                                                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${TX_STATUS_STYLE[s] ?? 'bg-surface-variant text-on-surface-variant'}`}>
                                                        {t.status}
                                                    </span>
                                                </td>
                                            </tr>
                                        )
                                    })
                                )}
                            </tbody>
                        </table>
                    </div>

                    {/* Pagination */}
                    <div className="px-6 py-4 border-t border-surface-variant flex items-center justify-between text-body-sm text-on-surface-variant bg-surface-container-lowest">
                        <span>Showing {from} to {to} of {total.toLocaleString()} transactions</span>
                        <div className="flex gap-1 items-center">
                            <Link
                                href={pageHref(currentPage - 1)}
                                aria-disabled={currentPage <= 1}
                                className={`p-1 rounded hover:bg-surface-container ${currentPage <= 1 ? 'pointer-events-none opacity-40' : ''}`}
                            >
                                <span className="material-symbols-outlined text-sm">chevron_left</span>
                            </Link>

                            {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                                let p: number
                                if (totalPages <= 5)                  p = i + 1
                                else if (currentPage <= 3)            p = i + 1
                                else if (currentPage >= totalPages - 2) p = totalPages - 4 + i
                                else                                  p = currentPage - 2 + i
                                return (
                                    <Link
                                        key={p}
                                        href={pageHref(p)}
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
                                href={pageHref(currentPage + 1)}
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
