'use client'
import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'

type Result = { type: string; label: string; sub: string; href: string }

const TYPE_ICON: Record<string, string> = {
    order: 'receipt_long',
    restaurant: 'restaurant',
    rider: 'delivery_dining',
}

export default function SearchBar() {
    const [query, setQuery] = useState('')
    const [results, setResults] = useState<Result[]>([])
    const [open, setOpen] = useState(false)
    const [loading, setLoading] = useState(false)
    const router = useRouter()
    const wrapRef = useRef<HTMLDivElement>(null)

    useEffect(() => {
        if (!query.trim()) { setResults([]); return }
        setLoading(true)
        const t = setTimeout(() => {
            fetch(`/api/search?q=${encodeURIComponent(query)}`)
                .then(r => r.json())
                .then(data => { setResults(data); setLoading(false) })
                .catch(() => setLoading(false))
        }, 300)
        return () => clearTimeout(t)
    }, [query])

    useEffect(() => {
        function onClickOutside(e: MouseEvent) {
            if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setOpen(false)
        }
        document.addEventListener('mousedown', onClickOutside)
        return () => document.removeEventListener('mousedown', onClickOutside)
    }, [])

    function navigate(href: string) {
        router.push(href)
        setOpen(false)
        setQuery('')
    }

    return (
        <div ref={wrapRef} className="relative hidden sm:block">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
                search
            </span>
            <input
                type="text"
                value={query}
                onChange={e => { setQuery(e.target.value); setOpen(true) }}
                onFocus={() => setOpen(true)}
                onKeyDown={e => {
                    if (e.key === 'Escape') { setOpen(false); setQuery('') }
                    if (e.key === 'Enter' && results.length > 0) navigate(results[0].href)
                }}
                placeholder="Search orders, riders..."
                className="pl-10 pr-4 py-2 bg-surface-container rounded-full border-none focus:ring-2 focus:ring-primary-container text-sm w-64 text-on-surface placeholder:text-on-surface-variant/70 outline-none"
            />

            {open && query.trim() && (
                <div className="absolute top-full mt-2 left-0 w-80 bg-surface-container-lowest rounded-2xl shadow-xl border border-surface-container-highest overflow-hidden z-50">
                    {loading ? (
                        <div className="px-4 py-3 text-sm text-on-surface-variant flex items-center gap-2">
                            <span className="material-symbols-outlined animate-spin text-[16px]">progress_activity</span>
                            Searching...
                        </div>
                    ) : results.length === 0 ? (
                        <div className="px-4 py-5 text-center text-sm text-on-surface-variant">No results for &quot;{query}&quot;</div>
                    ) : (
                        <ul>
                            {results.map((r, i) => (
                                <li key={i}>
                                    <button
                                        className="w-full flex items-center gap-3 px-4 py-3 hover:bg-surface-container text-left transition-colors"
                                        onClick={() => navigate(r.href)}
                                    >
                                        <span className="material-symbols-outlined text-orange-400 text-[18px] shrink-0">
                                            {TYPE_ICON[r.type] ?? 'search'}
                                        </span>
                                        <div className="min-w-0">
                                            <p className="text-sm font-medium text-on-surface truncate">{r.label}</p>
                                            <p className="text-xs text-on-surface-variant capitalize">{r.type} · {r.sub}</p>
                                        </div>
                                    </button>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            )}
        </div>
    )
}
