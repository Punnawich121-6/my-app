'use client'

import { useTransition, useRef } from 'react'
import { approveRestaurant, rejectRestaurant } from '@/app/actions/restaurant'
import type { PendingRestaurant } from '@/app/lib/restaurant'
import MapViewer from './MapViewer'

export default function PendingApprovals({ restaurants }: { restaurants: PendingRestaurant[] }) {
    if (restaurants.length === 0) return null

    return (
        <div className="mb-8 rounded-xl overflow-hidden border border-amber-200 shadow-sm">
            {/* Header */}
            <div className="flex items-center gap-3 px-6 py-4 bg-amber-50 border-b border-amber-200">
                <div className="w-9 h-9 rounded-full bg-amber-100 flex items-center justify-center">
                    <span className="material-symbols-outlined text-amber-600 text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>
                        pending_actions
                    </span>
                </div>
                <div className="flex-1">
                    <h3 className="text-label-lg text-amber-900 font-semibold">รอการอนุมัติ</h3>
                    <p className="text-body-xs text-amber-700 mt-0.5">
                        มีร้านอาหาร {restaurants.length} ร้านที่สมัครเข้ามาและรอการพิจารณา
                    </p>
                </div>
                <span className="bg-amber-500 text-white text-label-sm font-semibold px-2.5 py-0.5 rounded-full min-w-[1.5rem] text-center">
                    {restaurants.length}
                </span>
            </div>

            {/* Rows */}
            <div className="bg-white divide-y divide-amber-50">
                {restaurants.map(r => (
                    <ApprovalRow key={r.id} restaurant={r} />
                ))}
            </div>
        </div>
    )
}

function ApprovalRow({ restaurant }: { restaurant: PendingRestaurant }) {
    const [isPending, startTransition] = useTransition()
    const dialogRef = useRef<HTMLDialogElement>(null)

    const appliedDate = restaurant.createdAt
        ? new Intl.DateTimeFormat('th-TH', { day: 'numeric', month: 'short', year: 'numeric' })
            .format(new Date(restaurant.createdAt))
        : null

    const appliedDateTime = restaurant.createdAt
        ? new Intl.DateTimeFormat('th-TH', {
            day: 'numeric', month: 'long', year: 'numeric',
            hour: '2-digit', minute: '2-digit',
          }).format(new Date(restaurant.createdAt))
        : null

    function handleApprove() {
        startTransition(() => approveRestaurant(restaurant.id))
    }

    function handleReject() {
        if (!confirm(`ปฏิเสธร้าน "${restaurant.name}" ใช่หรือไม่?`)) return
        startTransition(() => rejectRestaurant(restaurant.id))
    }

    function openDetail()  {
        dialogRef.current?.showModal()
        setTimeout(() => { window.dispatchEvent(new Event('resize')) }, 150)
    }
    function closeDetail() { dialogRef.current?.close() }

    return (
        <>
            <div className={`px-6 py-4 flex items-center gap-4 transition-opacity ${isPending ? 'opacity-40 pointer-events-none' : ''}`}>
                {/* Avatar */}
                <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center text-amber-800 font-bold text-sm shrink-0">
                    {restaurant.name.charAt(0).toUpperCase()}
                </div>

                {/* Info */}
                <div className="flex-1 min-w-0">
                    <p className="text-label-lg text-on-surface">{restaurant.name}</p>
                    <div className="flex flex-wrap gap-x-3 gap-y-0.5 mt-0.5">
                        {restaurant.category && (
                            <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                                <span className="material-symbols-outlined text-[13px]">category</span>
                                {restaurant.category}
                            </span>
                        )}
                        {restaurant.phone && (
                            <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                                <span className="material-symbols-outlined text-[13px]">phone</span>
                                {restaurant.phone}
                            </span>
                        )}
                        {restaurant.email && (
                            <span className="text-body-xs text-on-surface-variant flex items-center gap-1">
                                <span className="material-symbols-outlined text-[13px]">mail</span>
                                {restaurant.email}
                            </span>
                        )}
                    </div>
                    {restaurant.address && (
                        <p className="text-body-xs text-on-surface-variant mt-0.5 truncate max-w-sm">
                            {restaurant.address}
                        </p>
                    )}
                </div>

                {/* Date */}
                {appliedDate && (
                    <div className="hidden md:flex flex-col items-end shrink-0">
                        <span className="text-body-xs text-on-surface-variant">สมัครเมื่อ</span>
                        <span className="text-label-sm text-on-surface">{appliedDate}</span>
                    </div>
                )}

                {/* Actions */}
                <div className="flex items-center gap-2 shrink-0">
                    {/* View button */}
                    <button
                        onClick={openDetail}
                        title="ดูข้อมูลทั้งหมด"
                        className="w-8 h-8 rounded-full border border-outline-variant text-on-surface-variant hover:bg-surface-container hover:text-on-surface transition-colors flex items-center justify-center"
                    >
                        <span className="material-symbols-outlined text-[18px]">visibility</span>
                    </button>

                    <button
                        onClick={handleReject}
                        disabled={isPending}
                        className="border border-error text-error px-4 py-1.5 rounded-full text-label-sm hover:bg-error-container transition-colors disabled:opacity-50 flex items-center gap-1"
                    >
                        <span className="material-symbols-outlined text-[15px]">close</span>
                        ปฏิเสธ
                    </button>
                    <button
                        onClick={handleApprove}
                        disabled={isPending}
                        className="bg-green-600 text-white px-4 py-1.5 rounded-full text-label-sm hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center gap-1"
                    >
                        <span className="material-symbols-outlined text-[15px]">check</span>
                        อนุมัติ
                    </button>
                </div>
            </div>

            {/* Detail Modal */}
            <dialog
                ref={dialogRef}
                onClick={e => { if (e.target === dialogRef.current) closeDetail() }}
                style={{ width: 'min(calc(100vw - 2rem), 36rem)' }}
                className="m-auto rounded-2xl shadow-xl p-0 bg-surface-container-lowest border-0 backdrop:bg-black/50 backdrop:backdrop-blur-sm"
            >
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container">
                    <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center text-amber-800 font-bold shrink-0">
                            {restaurant.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                            <h3 className="text-headline-sm text-on-surface">{restaurant.name}</h3>
                            <span className="inline-flex items-center gap-1 text-label-sm text-amber-700 bg-amber-100 px-2 py-0.5 rounded-full mt-0.5">
                                <span className="w-1.5 h-1.5 rounded-full bg-amber-500 shrink-0" />
                                รอการอนุมัติ
                            </span>
                        </div>
                    </div>
                    <button
                        onClick={closeDetail}
                        className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors"
                    >
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                {/* Body */}
                <div className="px-6 py-5 flex flex-col gap-5 overflow-y-auto max-h-[65vh]">

                    {/* ข้อมูลร้าน */}
                    <section>
                        <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ข้อมูลร้านอาหาร</p>
                        <div className="flex flex-col gap-3">
                            <DetailRow icon="category"    label="ประเภทอาหาร" value={restaurant.category || '—'} />
                            <DetailRow icon="location_on" label="ที่อยู่"      value={restaurant.address  || '—'} multiline />
                            <DetailRow icon="schedule"    label="เวลาเปิด-ปิด"
                                value={`${restaurant.open_time ?? '—'} – ${restaurant.close_time ?? '—'}`} />
                            {restaurant.lat && restaurant.lng ? (
                                <div>
                                    <p className="text-label-sm text-on-surface-variant mb-1.5 flex items-center gap-1.5">
                                        <span className="material-symbols-outlined text-[15px]">my_location</span>
                                        ตำแหน่งร้าน
                                    </p>
                                    <div style={{ height: '200px' }} className="rounded-xl overflow-hidden border border-outline-variant">
                                        <MapViewer lat={Number(restaurant.lat)} lng={Number(restaurant.lng)} />
                                    </div>
                                    <p className="text-body-xs text-on-surface-variant mt-1 font-mono">
                                        {Number(restaurant.lat).toFixed(6)}, {Number(restaurant.lng).toFixed(6)}
                                    </p>
                                </div>
                            ) : (
                                <DetailRow icon="my_location" label="ตำแหน่งร้าน" value="ยังไม่ได้ปักหมุด" />
                            )}
                        </div>
                    </section>

                    {/* ข้อมูลผู้ติดต่อ */}
                    <section>
                        <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ผู้ติดต่อ</p>
                        <div className="flex flex-col gap-3">
                            <DetailRow icon="person" label="ชื่อเจ้าของร้าน" value={restaurant.owner_name || '—'} />
                            <DetailRow icon="phone"  label="เบอร์โทรศัพท์"   value={restaurant.phone      || '—'} />
                            <DetailRow icon="mail"   label="อีเมล"            value={restaurant.email      || '—'} />
                            <DetailRow icon="chat"   label="Line ID"          value={restaurant.line_id    || '—'} />
                        </div>
                    </section>

                    {/* บัญชีธนาคาร */}
                    <section>
                        <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">บัญชีรับเงิน</p>
                        <div className="bg-surface-container rounded-xl px-4 py-3 flex flex-col gap-3">
                            <DetailRow icon="account_balance" label="ธนาคาร"    value={restaurant.bank_name    || '—'} />
                            <DetailRow icon="badge"           label="ชื่อบัญชี" value={restaurant.account_name || '—'} />
                            <DetailRow icon="tag"             label="เลขบัญชี"  value={restaurant.account_no   || '—'} mono />
                        </div>
                    </section>

                    {/* เอกสาร */}
                    <section>
                        <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">เอกสาร</p>
                        <div className="flex flex-col gap-3">
                            <DetailRow icon="id_card" label="เลขบัตรประชาชน"    value={restaurant.id_card            || '—'} mono />
                            <DetailRow icon="article" label="เลขทะเบียนพาณิชย์" value={restaurant.business_license   || '—'} mono />
                        </div>
                    </section>

                    {appliedDateTime && (
                        <DetailRow icon="calendar_today" label="วันที่สมัคร" value={appliedDateTime} />
                    )}
                </div>

                {/* Footer */}
                <div className="flex gap-3 px-6 py-4 border-t border-surface-container bg-surface-container-lowest rounded-b-2xl">
                    <button
                        onClick={() => { closeDetail(); handleReject() }}
                        disabled={isPending}
                        className="flex-1 border border-error text-error text-label-lg py-2.5 rounded-full hover:bg-error-container transition-colors disabled:opacity-50"
                    >
                        ปฏิเสธ
                    </button>
                    <button
                        onClick={() => { closeDetail(); handleApprove() }}
                        disabled={isPending}
                        className="flex-1 bg-green-600 text-white text-label-lg py-2.5 rounded-full hover:bg-green-700 transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
                    >
                        <span className="material-symbols-outlined text-[18px]">check_circle</span>
                        อนุมัติ
                    </button>
                </div>
            </dialog>
        </>
    )
}

function DetailRow({
    icon, label, value, multiline = false, mono = false,
}: {
    icon: string
    label: string
    value: string
    multiline?: boolean
    mono?: boolean
}) {
    return (
        <div className="flex gap-3">
            <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center shrink-0 mt-0.5">
                <span className="material-symbols-outlined text-on-surface-variant text-[18px]">{icon}</span>
            </div>
            <div className="flex-1 min-w-0">
                <p className="text-label-sm text-on-surface-variant">{label}</p>
                <p className={`text-body-md text-on-surface mt-0.5 ${multiline ? '' : 'truncate'} ${mono ? 'font-mono tracking-wider' : ''}`}>
                    {value}
                </p>
            </div>
        </div>
    )
}
