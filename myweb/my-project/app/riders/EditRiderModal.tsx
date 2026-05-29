'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import { updateRider, type RiderFormState } from '@/app/actions/rider'

const INITIAL: RiderFormState = { success: false, error: null }

const VEHICLES = [
    { value: 'motorcycle',    label: 'มอเตอร์ไซค์',  icon: 'two_wheeler' },
    { value: 'car',           label: 'รถยนต์',        icon: 'directions_car' },
    { value: 'bicycle',       label: 'จักรยาน',       icon: 'pedal_bike' },
    { value: 'electric_bike', label: 'จักรยานไฟฟ้า',  icon: 'electric_bike' },
]

const STATUSES = [
    { value: 'Available', label: 'Available', desc: 'พร้อมรับงาน' },
    { value: 'Busy',      label: 'Busy',      desc: 'กำลังส่งอาหาร' },
    { value: 'Offline',   label: 'Offline',   desc: 'ออฟไลน์' },
    { value: 'Pending',   label: 'Pending',   desc: 'รอการยืนยัน' },
]

const INPUT = "w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"

type RiderData = {
    id:            string
    name:          string
    email:         string
    phone:         string
    vehicle:       string
    status:        string
    rating:        number | null
    runsCompleted: number
    isVerified:    boolean
}

export default function EditRiderModal({ rider }: { rider: RiderData }) {
    const [state, formAction, pending] = useActionState(updateRider, INITIAL)
    const dialogRef = useRef<HTMLDialogElement>(null)
    const formRef   = useRef<HTMLFormElement>(null)

    const [selectedVehicle, setSelectedVehicle] = useState(rider.vehicle)
    const [selectedStatus,  setSelectedStatus]  = useState(rider.status)
    const [isVerified,      setIsVerified]       = useState(rider.isVerified)

    useEffect(() => {
        if (state.success) dialogRef.current?.close()
    }, [state.success])

    function open()  { dialogRef.current?.showModal() }
    function close() { if (!pending) dialogRef.current?.close() }

    return (
        <>
            <button onClick={open} title="Edit"
                className="text-on-surface-variant hover:text-primary-container p-1 transition-colors ml-2">
                <span className="material-symbols-outlined text-[20px]">edit</span>
            </button>

            <dialog
                ref={dialogRef}
                onClick={e => { if (e.target === dialogRef.current) close() }}
                style={{ width: 'min(calc(100vw - 2rem), 34rem)' }}
                className="m-auto rounded-2xl shadow-xl p-0 bg-surface-container-lowest border-0 backdrop:bg-black/50 backdrop:backdrop-blur-sm"
            >
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container">
                    <div>
                        <h3 className="text-headline-sm text-on-surface">แก้ไขข้อมูลไรเดอร์</h3>
                        <p className="text-body-sm text-on-surface-variant mt-0.5">{rider.name}</p>
                    </div>
                    <button type="button" onClick={close} disabled={pending}
                        className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <form ref={formRef} action={formAction}>
                    <input type="hidden" name="riderId"     value={rider.id} />
                    <input type="hidden" name="vehicle"     value={selectedVehicle} />
                    <input type="hidden" name="status"      value={selectedStatus} />
                    <input type="hidden" name="isVerified"  value={isVerified ? '1' : '0'} />

                    <div className="px-6 py-5 flex flex-col gap-6 overflow-y-auto max-h-[calc(100dvh-14rem)] sm:max-h-[65vh]">
                        {state.error && (
                            <div className="flex items-center gap-2 bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-xl">
                                <span className="material-symbols-outlined text-[18px] shrink-0">error</span>
                                {state.error}
                            </div>
                        )}

                        {/* ข้อมูลส่วนตัว */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ข้อมูลส่วนตัว</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        ชื่อ-นามสกุล <span className="text-error">*</span>
                                    </label>
                                    <input name="name" required defaultValue={rider.name} className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        เบอร์โทรศัพท์ <span className="text-error">*</span>
                                    </label>
                                    <input name="phone" type="tel" required defaultValue={rider.phone} className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">อีเมล</label>
                                    <input name="email" type="email" defaultValue={rider.email} className={INPUT} />
                                </div>
                            </div>
                        </section>

                        {/* ยานพาหนะ */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ยานพาหนะ</p>
                            <div className="grid grid-cols-2 gap-3">
                                {VEHICLES.map(v => (
                                    <button
                                        key={v.value}
                                        type="button"
                                        onClick={() => setSelectedVehicle(v.value)}
                                        className={`flex items-center gap-3 border-2 rounded-xl p-3 transition-colors ${
                                            selectedVehicle === v.value
                                                ? 'border-primary-container bg-primary-container/10'
                                                : 'border-outline-variant hover:bg-surface-container'
                                        }`}
                                    >
                                        <span className={`material-symbols-outlined text-[22px] ${selectedVehicle === v.value ? 'text-primary-container' : 'text-on-surface-variant'}`}>
                                            {v.icon}
                                        </span>
                                        <span className="text-label-md text-on-surface">{v.label}</span>
                                    </button>
                                ))}
                            </div>
                        </section>

                        {/* สถานะ */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">สถานะ</p>
                            <div className="grid grid-cols-2 gap-3">
                                {STATUSES.map(opt => (
                                    <button
                                        key={opt.value}
                                        type="button"
                                        onClick={() => setSelectedStatus(opt.value)}
                                        className={`border-2 rounded-xl p-3 text-center transition-colors ${
                                            selectedStatus === opt.value
                                                ? 'border-primary-container bg-primary-container/10'
                                                : 'border-outline-variant hover:bg-surface-container'
                                        }`}
                                    >
                                        <p className="text-label-md text-on-surface">{opt.label}</p>
                                        <p className="text-body-xs text-on-surface-variant mt-0.5">{opt.desc}</p>
                                    </button>
                                ))}
                            </div>
                        </section>

                        {/* การยืนยันตัวตน */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">การยืนยันตัวตน</p>
                            <button
                                type="button"
                                onClick={() => setIsVerified(v => !v)}
                                className={`w-full flex items-center justify-between border-2 rounded-xl px-4 py-3 transition-colors ${
                                    isVerified
                                        ? 'border-green-500 bg-green-50'
                                        : 'border-outline-variant hover:bg-surface-container'
                                }`}
                            >
                                <div className="flex items-center gap-3">
                                    <span className={`material-symbols-outlined text-[22px] ${isVerified ? 'text-green-600' : 'text-on-surface-variant'}`}>
                                        {isVerified ? 'verified_user' : 'shield'}
                                    </span>
                                    <div className="text-left">
                                        <p className="text-label-md text-on-surface">ยืนยันตัวตนแล้ว</p>
                                        <p className="text-body-xs text-on-surface-variant">{isVerified ? 'ไรเดอร์ได้รับการยืนยันแล้ว' : 'คลิกเพื่อยืนยันตัวตน'}</p>
                                    </div>
                                </div>
                                <div className={`w-11 h-6 rounded-full transition-colors relative ${isVerified ? 'bg-green-500' : 'bg-surface-variant'}`}>
                                    <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform ${isVerified ? 'translate-x-5' : 'translate-x-0.5'}`} />
                                </div>
                            </button>
                        </section>

                        {/* สถิติ (แสดงอย่างเดียว) */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">สถิติ</p>
                            <div className="grid grid-cols-2 gap-3">
                                <div className="bg-surface-container rounded-xl p-3 text-center">
                                    <p className="text-headline-sm text-on-surface">{rider.runsCompleted.toLocaleString()}</p>
                                    <p className="text-label-sm text-on-surface-variant mt-0.5">รอบการส่ง</p>
                                </div>
                                <div className="bg-surface-container rounded-xl p-3 text-center">
                                    <p className="text-headline-sm text-on-surface">
                                        {rider.rating !== null ? Number(rider.rating).toFixed(1) : '—'}
                                    </p>
                                    <p className="text-label-sm text-on-surface-variant mt-0.5">คะแนนเฉลี่ย</p>
                                </div>
                            </div>
                        </section>
                    </div>

                    <div className="flex gap-3 px-6 py-4 border-t border-surface-container bg-surface-container-lowest rounded-b-2xl">
                        <button type="button" onClick={close} disabled={pending}
                            className="flex-1 border border-outline-variant text-on-surface text-label-lg py-2.5 rounded-full hover:bg-surface-container transition-colors disabled:opacity-50">
                            ยกเลิก
                        </button>
                        <button type="submit" disabled={pending}
                            className="flex-1 bg-primary-container text-on-primary text-label-lg py-2.5 rounded-full hover:bg-primary transition-colors disabled:opacity-60 flex items-center justify-center gap-2">
                            {pending ? (
                                <>
                                    <span className="material-symbols-outlined text-[18px] animate-spin">progress_activity</span>
                                    กำลังบันทึก...
                                </>
                            ) : (
                                <>
                                    <span className="material-symbols-outlined text-[18px]">save</span>
                                    บันทึก
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </dialog>
        </>
    )
}
