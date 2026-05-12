'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import { addRider, type RiderFormState } from '@/app/actions/rider'

const INITIAL: RiderFormState = { success: false, error: null }

const VEHICLES = [
    { value: 'motorcycle',    label: 'มอเตอร์ไซค์',   icon: 'two_wheeler' },
    { value: 'car',           label: 'รถยนต์',         icon: 'directions_car' },
    { value: 'bicycle',       label: 'จักรยาน',        icon: 'pedal_bike' },
    { value: 'electric_bike', label: 'จักรยานไฟฟ้า',   icon: 'electric_bike' },
]

const INPUT = "w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"

export default function AddRiderModal() {
    const [state, formAction, pending] = useActionState(addRider, INITIAL)
    const dialogRef = useRef<HTMLDialogElement>(null)
    const formRef   = useRef<HTMLFormElement>(null)
    const [selectedVehicle, setSelectedVehicle] = useState('motorcycle')
    const [selectedStatus, setSelectedStatus]   = useState<'Pending' | 'Available' | 'Offline'>('Pending')

    useEffect(() => {
        if (state.success) {
            dialogRef.current?.close()
            formRef.current?.reset()
            setSelectedVehicle('motorcycle')
            setSelectedStatus('Pending')
        }
    }, [state.success])

    function open()  { dialogRef.current?.showModal() }
    function close() { if (!pending) { dialogRef.current?.close(); formRef.current?.reset() } }

    return (
        <>
            <button
                onClick={open}
                className="bg-primary-container text-on-primary text-label-lg px-6 py-3 rounded-full hover:bg-primary transition-colors shadow-sm flex items-center gap-2"
            >
                <span className="material-symbols-outlined text-[20px]">person_add</span>
                Add New Rider
            </button>

            <dialog
                ref={dialogRef}
                onClick={e => { if (e.target === dialogRef.current) close() }}
                style={{ width: 'min(calc(100vw - 2rem), 32rem)' }}
                className="m-auto rounded-2xl shadow-xl p-0 bg-surface-container-lowest border-0 backdrop:bg-black/50 backdrop:backdrop-blur-sm"
            >
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container">
                    <div>
                        <h3 className="text-headline-sm text-on-surface">เพิ่มไรเดอร์ใหม่</h3>
                        <p className="text-body-sm text-on-surface-variant mt-0.5">กรอกข้อมูลไรเดอร์ให้ครบถ้วน</p>
                    </div>
                    <button type="button" onClick={close} disabled={pending}
                        className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <form ref={formRef} action={formAction}>
                    <input type="hidden" name="vehicle" value={selectedVehicle} />
                    <input type="hidden" name="status"  value={selectedStatus} />

                    <div className="px-6 py-5 flex flex-col gap-5 overflow-y-auto max-h-[60vh]">
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
                                    <input name="name" required placeholder="เช่น สมชาย ใจดี" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        เบอร์โทรศัพท์ <span className="text-error">*</span>
                                    </label>
                                    <input name="phone" type="tel" required placeholder="0812345678" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">อีเมล</label>
                                    <input name="email" type="email" placeholder="rider@example.com" className={INPUT} />
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

                        {/* สถานะเริ่มต้น */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">สถานะเริ่มต้น</p>
                            <div className="flex gap-3">
                                {[
                                    { value: 'Pending',   label: 'Pending',   desc: 'รอการยืนยัน' },
                                    { value: 'Available', label: 'Available', desc: 'พร้อมรับงาน' },
                                    { value: 'Offline',   label: 'Offline',   desc: 'ออฟไลน์' },
                                ].map(opt => (
                                    <button
                                        key={opt.value}
                                        type="button"
                                        onClick={() => setSelectedStatus(opt.value as typeof selectedStatus)}
                                        className={`flex-1 border-2 rounded-xl p-3 text-center transition-colors ${
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
                                    <span className="material-symbols-outlined text-[18px]">person_add</span>
                                    เพิ่มไรเดอร์
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </dialog>
        </>
    )
}
