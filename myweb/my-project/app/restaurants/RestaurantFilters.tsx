'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useCallback, useRef } from 'react'

export default function RestaurantFilters({
    currentStatus,
    currentCategory,
    currentSearch,
    categories,
}: {
    currentStatus:   string
    currentCategory: string
    currentSearch:   string
    categories:      string[]
}) {
    const router      = useRouter()
    const searchParams = useSearchParams()
    const searchRef   = useRef<HTMLInputElement>(null)

    const updateFilter = useCallback((updates: Record<string, string>) => {
        const params = new URLSearchParams(searchParams.toString())
        Object.entries(updates).forEach(([k, v]) => params.set(k, v))
        params.set('page', '1')
        router.push(`?${params.toString()}`)
    }, [router, searchParams])

    const handleSearch = useCallback(() => {
        updateFilter({ search: searchRef.current?.value ?? '' })
    }, [updateFilter])

    return (
        <div className="p-4 border-b border-surface-container flex flex-wrap gap-4 items-center justify-between bg-surface-bright rounded-t-xl">
            <div className="flex gap-3 flex-wrap">
                {/* Category */}
                <div className="relative">
                    <select
                        value={currentCategory}
                        onChange={e => updateFilter({ category: e.target.value })}
                        className="appearance-none bg-white border border-outline-variant text-on-surface text-body-sm rounded-lg pl-4 pr-10 py-2 focus:outline-none focus:ring-1 focus:ring-primary-container focus:border-primary-container cursor-pointer"
                    >
                        <option value="ALL">All Categories</option>
                        {categories.map(c => (
                            <option key={c} value={c}>{c}</option>
                        ))}
                    </select>
                    <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[20px]">expand_more</span>
                </div>

                {/* Status */}
                <div className="relative">
                    <select
                        value={currentStatus}
                        onChange={e => updateFilter({ status: e.target.value })}
                        className="appearance-none bg-white border border-outline-variant text-on-surface text-body-sm rounded-lg pl-4 pr-10 py-2 focus:outline-none focus:ring-1 focus:ring-primary-container focus:border-primary-container cursor-pointer"
                    >
                        <option value="ALL">All Statuses</option>
                        <option value="active">Active</option>
                        <option value="pending">Pending</option>
                        <option value="inactive">Inactive</option>
                    </select>
                    <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[20px]">expand_more</span>
                </div>
            </div>

            {/* Search */}
            <div className="relative w-full sm:w-64">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">search</span>
                <input
                    ref={searchRef}
                    defaultValue={currentSearch}
                    onKeyDown={e => e.key === 'Enter' && handleSearch()}
                    className="w-full pl-10 pr-10 py-2 bg-white border border-outline-variant rounded-lg text-body-sm focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"
                    placeholder="Search by name..."
                    type="text"
                />
                <button
                    onClick={handleSearch}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-primary-container transition-colors"
                >
                    <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                </button>
            </div>
        </div>
    )
}
