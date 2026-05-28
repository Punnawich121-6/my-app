'use client'
import { useState, useRef, useEffect } from 'react'
import Link from 'next/link'
import { useRouter, useSearchParams } from 'next/navigation'
import type { TopPerformer } from '@/app/lib/dashboard'

function formatCurrency(amount: number): string {
    if (amount >= 1000) return `$${(amount / 1000).toFixed(1)}k`
    return `$${amount.toFixed(0)}`
}

type SortBy = 'orders' | 'revenue'

export default function TopPerformersCard({
    performers,
    sortBy,
}: {
    performers: TopPerformer[]
    sortBy: SortBy
}) {
    const router      = useRouter()
    const searchParams = useSearchParams()
    const [menuOpen, setMenuOpen] = useState(false)
    const menuRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        function handler(e: MouseEvent) {
            if (menuRef.current && !menuRef.current.contains(e.target as Node)) setMenuOpen(false)
        }
        document.addEventListener('mousedown', handler)
        return () => document.removeEventListener('mousedown', handler)
    }, [])

    function changeSort(s: SortBy) {
        const params = new URLSearchParams(searchParams.toString())
        params.set('sort', s)
        router.push(`/dashboard?${params.toString()}`)
        setMenuOpen(false)
    }

    const subtitle = sortBy === 'revenue' ? 'By revenue' : 'By order count'

    return (
        <div className="bg-surface-container-lowest rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 p-6 flex flex-col">

            {/* Header */}
            <div className="flex justify-between items-start mb-6">
                <div>
                    <h3 className="text-headline-sm text-on-surface">Top Performers</h3>
                    <p className="text-body-sm text-on-surface-variant mt-0.5">{subtitle}</p>
                </div>

                {/* ⋮ menu */}
                <div ref={menuRef} className="relative">
                    <button
                        onClick={() => setMenuOpen(v => !v)}
                        className="p-1.5 rounded-full hover:bg-surface-container transition-colors text-on-surface-variant"
                    >
                        <span className="material-symbols-outlined">more_vert</span>
                    </button>

                    {menuOpen && (
                        <div className="absolute right-0 top-full mt-1 w-44 bg-surface-container-lowest rounded-xl shadow-xl border border-surface-container-highest z-50 overflow-hidden py-1">
                            <p className="px-3 py-1.5 text-label-sm text-on-surface-variant uppercase tracking-wider">Sort by</p>
                            {([
                                { value: 'orders',  label: 'Order Count', icon: 'receipt_long' },
                                { value: 'revenue', label: 'Revenue',     icon: 'attach_money' },
                            ] as { value: SortBy; label: string; icon: string }[]).map(opt => (
                                <button
                                    key={opt.value}
                                    onClick={() => changeSort(opt.value)}
                                    className={`w-full flex items-center gap-2.5 px-3 py-2.5 text-sm transition-colors
                                        ${sortBy === opt.value
                                            ? 'text-primary-container bg-primary-container/10 font-semibold'
                                            : 'text-on-surface hover:bg-surface-container'
                                        }`}
                                >
                                    <span className="material-symbols-outlined text-[18px]">{opt.icon}</span>
                                    {opt.label}
                                    {sortBy === opt.value && (
                                        <span className="material-symbols-outlined text-[16px] ml-auto">check</span>
                                    )}
                                </button>
                            ))}
                        </div>
                    )}
                </div>
            </div>

            {/* List */}
            <div className="space-y-5 flex-1">
                {performers.length === 0 ? (
                    <p className="text-body-md text-on-surface-variant">No data yet.</p>
                ) : (
                    performers.map((r, i) => (
                        <div key={r.id} className="flex items-center gap-4">
                            <span className={`text-label-sm w-5 h-5 shrink-0 flex items-center justify-center rounded-full font-bold
                                ${i === 0 ? 'bg-amber-400 text-white' : i === 1 ? 'bg-slate-300 text-slate-700' : i === 2 ? 'bg-orange-300 text-white' : 'text-on-surface-variant'}`}>
                                {i + 1}
                            </span>
                            <div className="w-11 h-11 rounded-xl overflow-hidden bg-surface-container shrink-0">
                                {r.imageUrl ? (
                                    // eslint-disable-next-line @next/next/no-img-element
                                    <img alt={r.name} className="w-full h-full object-cover" src={r.imageUrl} />
                                ) : (
                                    <div className="w-full h-full flex items-center justify-center text-on-surface-variant text-label-sm font-bold">
                                        {r.name.charAt(0)}
                                    </div>
                                )}
                            </div>
                            <div className="flex-1 min-w-0">
                                <h4 className="text-label-lg text-on-surface truncate">{r.name}</h4>
                                <p className="text-body-sm text-on-surface-variant">
                                    {Number(r.orderCount)} orders
                                </p>
                            </div>
                            <div className="text-right">
                                <p className="text-label-lg text-primary-container font-semibold">
                                    {formatCurrency(Number(r.revenue))}
                                </p>
                            </div>
                        </div>
                    ))
                )}
            </div>

            {/* Footer */}
            <Link
                href="/restaurants"
                className="w-full mt-6 py-2 bg-surface text-primary-container text-label-md rounded-full border border-outline-variant hover:bg-primary-container hover:text-white transition-colors text-center block"
            >
                View Full Rankings
            </Link>
        </div>
    )
}
