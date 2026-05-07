'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import { addRestaurant, type RestaurantFormState } from '@/app/actions/restaurant'

const INITIAL: RestaurantFormState = { success: false, error: null }

const CATEGORIES = [
    'อาหารไทย', 'อาหารญี่ปุ่น', 'อาหารเกาหลี', 'อาหารจีน', 'อาหารอิตาลี',
    'อาหารอเมริกัน', 'อาหารอินเดีย', 'อาหารเวียดนาม', 'อาหารตะวันตก',
    'ฟาสต์ฟู้ด', 'พิซซ่า', 'ซูชิ', 'ก๋วยเตี๋ยว', 'ข้าวมันไก่',
    'กาแฟ & เบเกอรี่', 'ไอศกรีม & ของหวาน', 'เครื่องดื่ม', 'อื่นๆ',
]

export default function AddRestaurantModal() {
    const [state, formAction, pending] = useActionState(addRestaurant, INITIAL)
    const dialogRef = useRef<HTMLDialogElement>(null)
    const formRef   = useRef<HTMLFormElement>(null)
    const [selectedStatus, setSelectedStatus] = useState<'pending' | 'active'>('pending')

    useEffect(() => {
        if (state.success) {
            dialogRef.current?.close()
            formRef.current?.reset()
            setSelectedStatus('pending')
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
                <span className="material-symbols-outlined text-[20px]">add</span>
                Add New Restaurant
            </button>

            <dialog
                ref={dialogRef}
                onClick={e => { if (e.target === dialogRef.current) close() }}
                style={{ width: 'min(calc(100vw - 2rem), 32rem)' }}
                className="m-auto rounded-2xl shadow-xl p-0 bg-surface-container-lowest border-0 backdrop:bg-black/50 backdrop:backdrop-blur-sm"
            >
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container">
                    <div>
                        <h3 className="text-headline-sm text-on-surface">เพิ่มร้านอาหารใหม่</h3>
                        <p className="text-body-sm text-on-surface-variant mt-0.5">กรอกข้อมูลร้านอาหารให้ครบถ้วน</p>
                    </div>
                    <button
                        type="button"
                        onClick={close}
                        disabled={pending}
                        className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors"
                    >
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                {/* Form — ครอบทั้ง body + footer เพื่อให้ submit button อยู่ใน form */}
                <form ref={formRef} action={formAction}>

                    {/* Scrollable body */}
                    <div className="px-6 py-5 flex flex-col gap-5 overflow-y-auto max-h-[60vh]">

                        {/* Error */}
                        {state.error && (
                            <div className="flex items-center gap-2 bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-xl">
                                <span className="material-symbols-outlined text-[18px] shrink-0">error</span>
                                {state.error}
                            </div>
                        )}

                        {/* ข้อมูลร้าน */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ข้อมูลร้านอาหาร</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        ชื่อร้านอาหาร <span className="text-error">*</span>
                                    </label>
                                    <input
                                        name="name"
                                        required
                                        placeholder="เช่น ข้าวมันไก่นายหัว"
                                        className="w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"
                                    />
                                </div>

                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        ประเภทอาหาร <span className="text-error">*</span>
                                    </label>
                                    <div className="relative">
                                        <select
                                            name="category"
                                            required
                                            defaultValue=""
                                            className="w-full appearance-none border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors pr-10"
                                        >
                                            <option value="" disabled>เลือกประเภทอาหาร</option>
                                            {CATEGORIES.map(c => (
                                                <option key={c} value={c}>{c}</option>
                                            ))}
                                        </select>
                                        <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[20px]">expand_more</span>
                                    </div>
                                </div>

                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ที่อยู่ร้าน</label>
                                    <textarea
                                        name="address"
                                        rows={2}
                                        placeholder="เลขที่ ถนน แขวง/ตำบล เขต/อำเภอ จังหวัด"
                                        className="w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors resize-none"
                                    />
                                </div>
                            </div>
                        </section>

                        {/* ข้อมูลการติดต่อ */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ข้อมูลการติดต่อ</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        เบอร์โทรศัพท์ <span className="text-error">*</span>
                                    </label>
                                    <input
                                        name="phone"
                                        type="tel"
                                        required
                                        placeholder="0812345678"
                                        className="w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"
                                    />
                                </div>

                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">อีเมล</label>
                                    <input
                                        name="email"
                                        type="email"
                                        placeholder="restaurant@example.com"
                                        className="w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"
                                    />
                                </div>
                            </div>
                        </section>

                        {/* สถานะเริ่มต้น */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">การตั้งค่า</p>
                            <input type="hidden" name="status" value={selectedStatus} />
                            <div className="flex gap-3">
                                {[
                                    { value: 'pending', label: 'Pending Approval', desc: 'รอการอนุมัติ' },
                                    { value: 'active',  label: 'Active',           desc: 'เปิดใช้งานทันที' },
                                ].map(opt => (
                                    <button
                                        key={opt.value}
                                        type="button"
                                        onClick={() => setSelectedStatus(opt.value as 'pending' | 'active')}
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

                    {/* Footer — อยู่ใน <form> ดังนั้น type="submit" ทำงานได้ตรงๆ */}
                    <div className="flex gap-3 px-6 py-4 border-t border-surface-container bg-surface-container-lowest rounded-b-2xl">
                        <button
                            type="button"
                            onClick={close}
                            disabled={pending}
                            className="flex-1 border border-outline-variant text-on-surface text-label-lg py-2.5 rounded-full hover:bg-surface-container transition-colors disabled:opacity-50"
                        >
                            ยกเลิก
                        </button>
                        <button
                            type="submit"
                            disabled={pending}
                            className="flex-1 bg-primary-container text-on-primary text-label-lg py-2.5 rounded-full hover:bg-primary transition-colors disabled:opacity-60 flex items-center justify-center gap-2"
                        >
                            {pending ? (
                                <>
                                    <span className="material-symbols-outlined text-[18px] animate-spin">progress_activity</span>
                                    กำลังบันทึก...
                                </>
                            ) : (
                                <>
                                    <span className="material-symbols-outlined text-[18px]">add</span>
                                    เพิ่มร้านอาหาร
                                </>
                            )}
                        </button>
                    </div>

                </form>
            </dialog>
        </>
    )
}
