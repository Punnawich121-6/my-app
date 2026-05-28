'use client'
import { useState, useRef, useEffect } from 'react'
import { useRouter } from 'next/navigation'

const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MONTHS = ['January','February','March','April','May','June',
                'July','August','September','October','November','December']

function toLocal(dateStr: string) {
    return new Date(dateStr + 'T00:00:00')
}

export default function DatePickerButton({ date }: { date: string }) {
    const router   = useRouter()
    const todayStr = new Date().toISOString().split('T')[0]
    const isToday  = date === todayStr
    const selected = toLocal(date)

    const [open, setOpen]         = useState(false)
    const [viewYear, setViewYear] = useState(selected.getFullYear())
    const [viewMonth, setViewMonth] = useState(selected.getMonth())
    const wrapRef = useRef<HTMLDivElement>(null)

    /* close on outside click */
    useEffect(() => {
        function handler(e: MouseEvent) {
            if (wrapRef.current && !wrapRef.current.contains(e.target as Node)) setOpen(false)
        }
        document.addEventListener('mousedown', handler)
        return () => document.removeEventListener('mousedown', handler)
    }, [])

    /* sync view when prop changes */
    useEffect(() => {
        setViewYear(selected.getFullYear())
        setViewMonth(selected.getMonth())
    }, [date]) // eslint-disable-line

    function prevMonth() {
        if (viewMonth === 0) { setViewMonth(11); setViewYear(y => y - 1) }
        else setViewMonth(m => m - 1)
    }
    function nextMonth() {
        const today = new Date()
        if (viewYear === today.getFullYear() && viewMonth === today.getMonth()) return
        if (viewMonth === 11) { setViewMonth(0); setViewYear(y => y + 1) }
        else setViewMonth(m => m + 1)
    }

    function selectDate(d: Date) {
        const str = d.toISOString().split('T')[0]
        setOpen(false)
        router.push(str === todayStr ? '/dashboard' : `/dashboard?date=${str}`)
    }

    /* build calendar grid */
    function buildDays() {
        const first = new Date(viewYear, viewMonth, 1).getDay()
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        const cells: (Date | null)[] = Array(first).fill(null)
        for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(viewYear, viewMonth, d))
        return cells
    }

    const cells = buildDays()
    const today = new Date()
    const canGoNext = !(viewYear === today.getFullYear() && viewMonth === today.getMonth())

    const displayDate = selected.toLocaleDateString('en-US', {
        weekday: 'long', month: 'short', day: 'numeric',
    })

    return (
        <div ref={wrapRef} className="relative self-start sm:self-auto">
            {/* Trigger button */}
            <button
                onClick={() => setOpen(v => !v)}
                className="flex items-center gap-2.5 bg-surface-container px-4 py-2 rounded-full border border-surface-variant hover:bg-surface-container-high transition-colors shadow-sm select-none"
            >
                <span className="material-symbols-outlined text-on-surface-variant text-[20px]">calendar_today</span>
                <span className="text-label-md text-on-surface">
                    {isToday ? 'Today, ' : ''}{displayDate}
                </span>
                {!isToday && (
                    <span
                        role="button"
                        onClick={e => { e.stopPropagation(); router.push('/dashboard') }}
                        className="text-on-surface-variant hover:text-on-surface ml-1"
                        title="Back to today"
                    >
                        <span className="material-symbols-outlined text-[16px]">close</span>
                    </span>
                )}
                <span className="material-symbols-outlined text-on-surface-variant text-[18px]">
                    {open ? 'expand_less' : 'expand_more'}
                </span>
            </button>

            {/* Calendar dropdown */}
            {open && (
                <div className="absolute right-0 top-full mt-2 z-50 bg-surface-container-lowest rounded-2xl shadow-xl border border-surface-container-highest p-4 w-72">

                    {/* Month navigation */}
                    <div className="flex items-center justify-between mb-4">
                        <button
                            onClick={prevMonth}
                            className="p-1.5 rounded-full hover:bg-surface-container transition-colors text-on-surface-variant"
                        >
                            <span className="material-symbols-outlined text-[20px]">chevron_left</span>
                        </button>
                        <span className="text-label-lg text-on-surface font-semibold">
                            {MONTHS[viewMonth]} {viewYear}
                        </span>
                        <button
                            onClick={nextMonth}
                            disabled={!canGoNext}
                            className="p-1.5 rounded-full hover:bg-surface-container transition-colors text-on-surface-variant disabled:opacity-30 disabled:cursor-not-allowed"
                        >
                            <span className="material-symbols-outlined text-[20px]">chevron_right</span>
                        </button>
                    </div>

                    {/* Day headers */}
                    <div className="grid grid-cols-7 mb-2">
                        {DAYS.map(d => (
                            <div key={d} className="text-center text-label-sm text-on-surface-variant py-1">
                                {d}
                            </div>
                        ))}
                    </div>

                    {/* Day cells */}
                    <div className="grid grid-cols-7 gap-y-1">
                        {cells.map((cell, i) => {
                            if (!cell) return <div key={i} />

                            const cellStr  = cell.toISOString().split('T')[0]
                            const isSelected = cellStr === date
                            const isTodayCell = cellStr === todayStr
                            const isFuture = cell > today

                            return (
                                <button
                                    key={i}
                                    disabled={isFuture}
                                    onClick={() => selectDate(cell)}
                                    className={`
                                        w-8 h-8 mx-auto rounded-full text-sm font-medium transition-colors
                                        ${isSelected
                                            ? 'bg-primary-container text-white'
                                            : isTodayCell
                                            ? 'border-2 border-primary-container text-primary-container hover:bg-primary-container/10'
                                            : isFuture
                                            ? 'text-on-surface-variant/30 cursor-not-allowed'
                                            : 'text-on-surface hover:bg-surface-container'
                                        }
                                    `}
                                >
                                    {cell.getDate()}
                                </button>
                            )
                        })}
                    </div>

                    {/* Quick shortcuts */}
                    <div className="mt-4 pt-3 border-t border-surface-container-highest flex gap-2">
                        {[
                            { label: 'Today',     days: 0 },
                            { label: 'Yesterday', days: 1 },
                            { label: '7 days ago', days: 7 },
                        ].map(({ label, days }) => {
                            const d = new Date()
                            d.setDate(d.getDate() - days)
                            const str = d.toISOString().split('T')[0]
                            return (
                                <button
                                    key={label}
                                    onClick={() => selectDate(d)}
                                    className={`flex-1 text-xs py-1.5 rounded-full border transition-colors ${
                                        str === date
                                            ? 'bg-primary-container text-white border-primary-container'
                                            : 'border-surface-container-highest text-on-surface-variant hover:bg-surface-container'
                                    }`}
                                >
                                    {label}
                                </button>
                            )
                        })}
                    </div>
                </div>
            )}
        </div>
    )
}
