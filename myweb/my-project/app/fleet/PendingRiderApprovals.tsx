'use client'

import { useTransition } from 'react'
import { approveRider, rejectRider } from '@/app/actions/rider'
import type { PendingRider } from '@/app/lib/fleet'

const VEHICLE_ICON: Record<string, string> = {
    motorcycle:    'two_wheeler',
    car:           'directions_car',
    bicycle:       'pedal_bike',
    electric_bike: 'electric_bike',
}

export default function PendingRiderApprovals({ riders }: { riders: PendingRider[] }) {
    if (riders.length === 0) return null

    return (
        <div className="mb-6 rounded-xl overflow-hidden border border-amber-200 shadow-sm">
            {/* Header */}
            <div className="flex items-center gap-3 px-6 py-4 bg-amber-50 border-b border-amber-200">
                <div className="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center">
                    <span className="material-symbols-outlined text-amber-600 text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                        pending_actions
                    </span>
                </div>
                <div className="flex-1">
                    <h3 className="text-label-lg text-amber-900 font-semibold">ไรเดอร์รอการยืนยัน</h3>
                    <p className="text-body-xs text-amber-700 mt-0.5">
                        มีไรเดอร์ {riders.length} คนที่สมัครเข้ามาและรอการพิจารณา
                    </p>
                </div>
                <span className="bg-amber-500 text-white text-label-sm font-semibold px-2.5 py-0.5 rounded-full min-w-[1.5rem] text-center">
                    {riders.length}
                </span>
            </div>

            {/* Rows */}
            <div className="bg-surface-container-lowest divide-y divide-surface-container">
                {riders.map(r => (
                    <ApprovalRow key={r.id} rider={r} />
                ))}
            </div>
        </div>
    )
}

function ApprovalRow({ rider }: { rider: PendingRider }) {
    const [isPending, startTransition] = useTransition()

    const appliedDate = new Intl.DateTimeFormat('th-TH', {
        day: 'numeric', month: 'short', year: 'numeric',
    }).format(new Date(rider.createdAt))

    function handleApprove() {
        startTransition(() => approveRider(rider.id))
    }

    function handleReject() {
        if (!confirm(`ปฏิเสธไรเดอร์ "${rider.name}" ใช่หรือไม่?`)) return
        startTransition(() => rejectRider(rider.id))
    }

    return (
        <div className={`px-4 sm:px-6 py-4 flex items-center gap-3 sm:gap-4 transition-opacity ${isPending ? 'opacity-40 pointer-events-none' : ''}`}>
            {/* Avatar */}
            <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center text-amber-800 font-bold text-sm shrink-0">
                {rider.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()}
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
                <p className="text-label-lg text-on-surface">{rider.name}</p>
                <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-0.5">
                    {rider.phone && (
                        <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                            <span className="material-symbols-outlined text-[13px]">phone</span>
                            {rider.phone}
                        </span>
                    )}
                    <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                        <span className="material-symbols-outlined text-[13px]">{VEHICLE_ICON[rider.vehicle] ?? 'two_wheeler'}</span>
                        {rider.vehicle}
                    </span>
                    {rider.email && !rider.email.endsWith('@riderapp.local') && (
                        <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                            <span className="material-symbols-outlined text-[13px]">mail</span>
                            {rider.email}
                        </span>
                    )}
                </div>
            </div>

            {/* Date */}
            <div className="hidden md:flex flex-col items-end shrink-0">
                <span className="text-body-xs text-on-surface-variant">สมัครเมื่อ</span>
                <span className="text-label-sm text-on-surface">{appliedDate}</span>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-2 shrink-0">
                <button
                    onClick={handleReject}
                    disabled={isPending}
                    className="border border-error text-error px-3 sm:px-4 py-1.5 rounded-full text-label-sm hover:bg-error-container transition-colors disabled:opacity-50 flex items-center gap-1"
                >
                    <span className="material-symbols-outlined text-[15px]">close</span>
                    <span className="hidden sm:inline">ปฏิเสธ</span>
                </button>
                <button
                    onClick={handleApprove}
                    disabled={isPending}
                    className="bg-green-600 text-white px-3 sm:px-4 py-1.5 rounded-full text-label-sm hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center gap-1"
                >
                    <span className="material-symbols-outlined text-[15px]">check</span>
                    <span className="hidden sm:inline">อนุมัติ</span>
                </button>
            </div>
        </div>
    )
}
