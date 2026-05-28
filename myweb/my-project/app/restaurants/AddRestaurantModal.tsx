'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import { addRestaurant, type RestaurantFormState } from '@/app/actions/restaurant'
import MapPicker from './MapPicker'

const INITIAL: RestaurantFormState = { success: false, error: null }

const CATEGORIES = [
    'อาหารไทย', 'อาหารญี่ปุ่น', 'อาหารเกาหลี', 'อาหารจีน', 'อาหารอิตาลี',
    'อาหารอเมริกัน', 'อาหารอินเดีย', 'อาหารเวียดนาม', 'อาหารตะวันตก',
    'ฟาสต์ฟู้ด', 'พิซซ่า', 'ซูชิ', 'ก๋วยเตี๋ยว', 'ข้าวมันไก่',
    'กาแฟ & เบเกอรี่', 'ไอศกรีม & ของหวาน', 'เครื่องดื่ม', 'อื่นๆ',
]

const INPUT = "w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"

export default function AddRestaurantModal() {
    const [state, formAction, pending] = useActionState(addRestaurant, INITIAL)
    const dialogRef = useRef<HTMLDialogElement>(null)
    const formRef   = useRef<HTMLFormElement>(null)
    const [selectedStatus, setSelectedStatus] = useState<'pending' | 'active'>('pending')
    const [coords, setCoords] = useState<{ lat: number | null; lng: number | null }>({ lat: null, lng: null })
    const [description, setDescription] = useState('')
    const [nameVal, setNameVal] = useState('')
    const [categoryVal, setCategoryVal] = useState('')
    const [aiLoading, setAiLoading] = useState(false)

    useEffect(() => {
        if (state.success) {
            dialogRef.current?.close()
            formRef.current?.reset()
            setSelectedStatus('pending')
            setCoords({ lat: null, lng: null })
            setDescription('')
            setNameVal('')
            setCategoryVal('')
        }
    }, [state.success])

    function open() {
        dialogRef.current?.showModal()
        setTimeout(() => window.dispatchEvent(new Event('resize')), 150)
    }
    function close() {
        if (!pending) { dialogRef.current?.close(); formRef.current?.reset() }
    }

    async function generateDescription() {
        if (!nameVal.trim()) { alert('กรุณากรอกชื่อร้านก่อน'); return }
        setAiLoading(true)
        try {
            const res = await fetch('/api/ai/description', {
                method: 'POST',
                headers: { 'content-type': 'application/json' },
                body: JSON.stringify({ name: nameVal, category: categoryVal || 'ร้านอาหาร' }),
            })
            const data = await res.json()
            if (data.description) setDescription(data.description)
        } catch { /* skip */ } finally {
            setAiLoading(false)
        }
    }

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
                style={{ width: 'min(calc(100vw - 2rem), 36rem)' }}
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

                <form ref={formRef} action={formAction}>

                    <div className="px-6 py-5 flex flex-col gap-6 overflow-y-auto max-h-[65vh]">

                        {state.error && (
                            <div className="flex items-center gap-2 bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-xl">
                                <span className="material-symbols-outlined text-[18px] shrink-0">error</span>
                                {state.error}
                            </div>
                        )}

                        {/* ข้อมูลร้านอาหาร */}
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
                                        className={INPUT}
                                        value={nameVal}
                                        onChange={e => setNameVal(e.target.value)}
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
                                            className={INPUT + ' appearance-none pr-10'}
                                            onChange={e => setCategoryVal(e.target.value)}
                                        >
                                            <option value="" disabled>เลือกประเภทอาหาร</option>
                                            {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                                        </select>
                                        <span className="material-symbols-outlined absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none text-[20px]">expand_more</span>
                                    </div>
                                </div>

                                {/* คำอธิบายร้าน (AI) */}
                                <div>
                                    <div className="flex items-center justify-between mb-1.5">
                                        <label className="text-label-md text-on-surface">คำอธิบายร้าน</label>
                                        <button
                                            type="button"
                                            onClick={generateDescription}
                                            disabled={aiLoading}
                                            className="flex items-center gap-1 text-primary-container text-body-xs hover:underline disabled:opacity-50 transition-opacity"
                                        >
                                            <span className="material-symbols-outlined text-[14px]">auto_awesome</span>
                                            {aiLoading ? 'กำลังสร้าง...' : 'สร้างด้วย AI'}
                                        </button>
                                    </div>
                                    <textarea
                                        name="description"
                                        rows={3}
                                        placeholder="คำอธิบายร้านที่น่าสนใจ หรือกด &quot;สร้างด้วย AI&quot;"
                                        className={INPUT + ' resize-none'}
                                        value={description}
                                        onChange={e => setDescription(e.target.value)}
                                    />
                                    {aiLoading && (
                                        <p className="text-body-xs text-primary-container mt-1 flex items-center gap-1">
                                            <span className="material-symbols-outlined text-[13px] animate-spin">progress_activity</span>
                                            AI กำลังเขียนคำอธิบาย...
                                        </p>
                                    )}
                                </div>

                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ที่อยู่ร้าน</label>
                                    <textarea name="address" rows={2}
                                        placeholder="เลขที่ ถนน แขวง/ตำบล เขต/อำเภอ จังหวัด"
                                        className={INPUT + ' resize-none'} />
                                </div>

                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="text-label-md text-on-surface mb-1.5 block">เวลาเปิด</label>
                                        <input name="open_time" type="time" className={INPUT} />
                                    </div>
                                    <div>
                                        <label className="text-label-md text-on-surface mb-1.5 block">เวลาปิด</label>
                                        <input name="close_time" type="time" className={INPUT} />
                                    </div>
                                </div>

                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        ตำแหน่งร้าน
                                        <span className="text-body-xs text-on-surface-variant ml-2 font-normal">คลิกบนแผนที่เพื่อปักหมุด</span>
                                    </label>
                                    <div style={{ height: '220px' }} className="rounded-xl overflow-hidden border border-outline-variant">
                                        <MapPicker
                                            initialLat={null}
                                            initialLng={null}
                                            onChange={(lat, lng) => setCoords({ lat, lng })}
                                        />
                                    </div>
                                    {coords.lat && coords.lng ? (
                                        <p className="text-body-xs text-on-surface-variant mt-1.5 flex items-center gap-1">
                                            <span className="material-symbols-outlined text-[13px] text-green-600">location_on</span>
                                            {coords.lat.toFixed(6)}, {coords.lng.toFixed(6)}
                                        </p>
                                    ) : (
                                        <p className="text-body-xs text-on-surface-variant mt-1.5">ยังไม่ได้ปักหมุด</p>
                                    )}
                                    <input type="hidden" name="lat" value={coords.lat !== null ? String(coords.lat) : ''} />
                                    <input type="hidden" name="lng" value={coords.lng !== null ? String(coords.lng) : ''} />
                                </div>
                            </div>
                        </section>

                        {/* ผู้ติดต่อ */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ผู้ติดต่อ</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ชื่อเจ้าของร้าน</label>
                                    <input name="owner_name" placeholder="ชื่อ-นามสกุล" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        เบอร์โทรศัพท์ <span className="text-error">*</span>
                                    </label>
                                    <input name="phone" type="tel" required placeholder="0812345678" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">อีเมล</label>
                                    <input name="email" type="email" placeholder="restaurant@example.com" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">Line ID</label>
                                    <input name="line_id" placeholder="@lineid" className={INPUT} />
                                </div>
                            </div>
                        </section>

                        {/* บัญชีรับเงิน */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">บัญชีรับเงิน</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ธนาคาร</label>
                                    <input name="bank_name" placeholder="เช่น กสิกรไทย, กรุงเทพ" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ชื่อบัญชี</label>
                                    <input name="account_name" placeholder="ชื่อบัญชีธนาคาร" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขบัญชี</label>
                                    <input name="account_no" placeholder="xxx-x-xxxxx-x" className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                            </div>
                        </section>

                        {/* เอกสาร */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">เอกสาร</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขบัตรประชาชน</label>
                                    <input name="id_card" placeholder="1 xxxx xxxxx xx x" maxLength={13} className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขทะเบียนพาณิชย์</label>
                                    <input name="business_license" placeholder="เลขทะเบียน (ถ้ามี)" className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                            </div>
                        </section>

                        {/* สถานะ */}
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

                    {/* Footer */}
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
