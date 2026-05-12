'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useCallback } from 'react'

const STATUS_BUTTONS = [
    { label: 'All Orders', value: 'ALL',        style: 'default' },
    { label: 'Pending',    value: 'pending',    style: 'default' },
    { label: 'Accepted',   value: 'accepted',   style: 'default' },
    { label: 'Preparing',  value: 'preparing',  style: 'default' },
    { label: 'Ready',      value: 'ready',      style: 'default' },
    { label: 'On the Way', value: 'delivering', style: 'default' },
    { label: 'Completed',  value: 'completed',  style: 'success' },
    { label: 'Cancelled',  value: 'cancelled',  style: 'error'   },
    { label: 'Delayed',    value: 'delayed',    style: 'error'   },
]

const ZONES = [
    { label: 'All Zones', value: 'ALL' },
    { label: 'Downtown',  value: 'Downtown' },
    { label: 'Northside', value: 'Northside' },
    { label: 'West End',  value: 'West End' },
]

function btnClass(style: string, active: boolean): string {
    if (active) return 'bg-primary-container text-on-primary'
    if (style === 'error')   return 'border border-outline-variant text-error hover:bg-error-container'
    if (style === 'success') return 'border border-outline-variant text-green-600 hover:bg-green-50'
    return 'border border-outline-variant text-on-surface hover:bg-surface-container'
}

export default function OrderFilters({
    currentStatus,
    currentZone,
}: {
    currentStatus: string
    currentZone: string
}) {
    const router = useRouter()
    const searchParams = useSearchParams()

    const updateFilter = useCallback((key: string, value: string) => {
        const params = new URLSearchParams(searchParams.toString())
        params.set(key, value)
        params.set('page', '1')
        router.push(`?${params.toString()}`, { scroll: false })
    }, [router, searchParams])

    return (
        <div className="p-4 border-b border-surface-container-highest flex flex-col xl:flex-row gap-4 justify-between items-start xl:items-center">
            <div className="flex items-center gap-2 overflow-x-auto w-full xl:w-auto pb-1 xl:pb-0">
                {STATUS_BUTTONS.map(btn => (
                    <button
                        key={btn.value}
                        onClick={() => updateFilter('status', btn.value)}
                        className={`shrink-0 text-label-lg px-4 py-2 rounded-full transition-colors ${btnClass(btn.style, currentStatus === btn.value)}`}
                    >
                        {btn.label}
                    </button>
                ))}
            </div>
            <div className="flex items-center gap-3 w-full xl:w-auto shrink-0">
                <div className="relative w-full xl:w-52">
                    <span className="material-symbols-outlined absolute left-3 top-2.5 text-sm text-on-surface-variant">filter_list</span>
                    <select
                        value={currentZone}
                        onChange={e => updateFilter('zone', e.target.value)}
                        className="w-full bg-surface-container-lowest border border-outline-variant rounded-lg py-2 pl-9 pr-8 text-body-sm text-on-surface appearance-none focus:outline-none focus:border-primary-container"
                    >
                        {ZONES.map(z => (
                            <option key={z.value} value={z.value}>{z.label}</option>
                        ))}
                    </select>
                    <span className="material-symbols-outlined absolute right-3 top-2.5 text-sm text-on-surface-variant pointer-events-none">expand_more</span>
                </div>
            </div>
        </div>
    )
}
