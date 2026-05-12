'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useTransition, useState, useEffect } from 'react'

const STATUSES = ['ALL', 'Available', 'Busy', 'Offline', 'Pending']

type Props = {
    currentStatus: string
    currentSearch: string
}

export default function RiderFilters({ currentStatus, currentSearch }: Props) {
    const router        = useRouter()
    const searchParams  = useSearchParams()
    const [, startTransition] = useTransition()
    const [search, setSearch] = useState(currentSearch)

    useEffect(() => { setSearch(currentSearch) }, [currentSearch])

    function buildHref(overrides: Record<string, string>) {
        const p = new URLSearchParams({
            status: currentStatus,
            search: currentSearch,
            page:   '1',
            ...overrides,
        })
        return `?${p.toString()}`
    }

    function handleSearch(val: string) {
        setSearch(val)
        startTransition(() => {
            const p = new URLSearchParams(searchParams.toString())
            p.set('search', val)
            p.set('page', '1')
            router.push(`?${p.toString()}`, { scroll: false })
        })
    }

    function handleStatus(s: string) {
        router.push(buildHref({ status: s }), { scroll: false })
    }

    return (
        <div className="px-6 py-4 border-b border-surface-container bg-surface-bright rounded-t-xl flex flex-wrap gap-4 items-center justify-between">
            {/* Status filters */}
            <div className="flex gap-2 flex-wrap">
                {STATUSES.map(s => (
                    <button
                        key={s}
                        onClick={() => handleStatus(s)}
                        className={`px-3 py-1.5 rounded-full text-label-sm transition-colors ${
                            currentStatus === s
                                ? 'bg-primary-container text-on-primary shadow-sm'
                                : 'bg-surface-container border border-outline-variant text-on-surface hover:border-primary-container'
                        }`}
                    >
                        {s === 'ALL' ? 'ทั้งหมด' : s}
                    </button>
                ))}
            </div>

            {/* Search */}
            <div className="relative w-full sm:w-64">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px]">
                    search
                </span>
                <input
                    type="text"
                    placeholder="ค้นหาชื่อหรือเบอร์โทร..."
                    value={search}
                    onChange={e => handleSearch(e.target.value)}
                    className="w-full pl-9 pr-4 py-2 bg-surface border border-outline-variant rounded-full text-body-md text-on-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors placeholder:text-on-surface-variant"
                />
                {search && (
                    <button
                        onClick={() => handleSearch('')}
                        className="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-on-surface"
                    >
                        <span className="material-symbols-outlined text-[16px]">close</span>
                    </button>
                )}
            </div>
        </div>
    )
}
