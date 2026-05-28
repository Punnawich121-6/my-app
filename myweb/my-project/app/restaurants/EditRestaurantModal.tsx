'use client'

import { useActionState, useEffect, useRef, useState } from 'react'
import { updateRestaurant, type RestaurantFormState } from '@/app/actions/restaurant'
import MapPicker from './MapPicker'
import ImageCropModal from '@/app/component/ImageCropModal'

const INITIAL: RestaurantFormState = { success: false, error: null }

const CATEGORIES = [
    'อาหารไทย', 'อาหารญี่ปุ่น', 'อาหารเกาหลี', 'อาหารจีน', 'อาหารอิตาลี',
    'อาหารอเมริกัน', 'อาหารอินเดีย', 'อาหารเวียดนาม', 'อาหารตะวันตก',
    'ฟาสต์ฟู้ด', 'พิซซ่า', 'ซูชิ', 'ก๋วยเตี๋ยว', 'ข้าวมันไก่',
    'กาแฟ & เบเกอรี่', 'ไอศกรีม & ของหวาน', 'เครื่องดื่ม', 'อื่นๆ',
]

type RestaurantData = {
    id: string
    name: string
    category: string
    address: string
    phone: string
    email: string
    status: string
    owner_name: string | null
    line_id: string | null
    bank_name: string | null
    account_name: string | null
    account_no: string | null
    id_card: string | null
    business_license: string | null
    open_time: string | null
    close_time: string | null
    lat: number | null
    lng: number | null
    imageUrl: string | null
    description?: string | null
}

const INPUT = "w-full border border-outline-variant rounded-xl px-4 py-2.5 text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"

export default function EditRestaurantModal({ restaurant }: { restaurant: RestaurantData }) {
    const [state, formAction, pending] = useActionState(updateRestaurant, INITIAL)
    const dialogRef = useRef<HTMLDialogElement>(null)
    const formRef   = useRef<HTMLFormElement>(null)
    const [coords, setCoords] = useState<{ lat: number | null; lng: number | null }>({
        lat: restaurant.lat != null ? Number(restaurant.lat) : null,
        lng: restaurant.lng != null ? Number(restaurant.lng) : null,
    })
    const [selectedStatus, setSelectedStatus] = useState(restaurant.status.toLowerCase())
    const [previewUrl, setPreviewUrl] = useState<string | null>(restaurant.imageUrl ?? null)
    const [uploading, setUploading] = useState(false)
    const fileRef = useRef<HTMLInputElement>(null)

    // AI description
    const [description, setDescription] = useState(restaurant.description ?? '')
    const [nameVal, setNameVal] = useState(restaurant.name)
    const [categoryVal, setCategoryVal] = useState(restaurant.category)
    const [aiLoading, setAiLoading] = useState(false)

    const [cropSrc, setCropSrc] = useState<string | null>(null)

    function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
        const file = e.target.files?.[0]
        if (!file) return
        const reader = new FileReader()
        reader.onload = ev => {
            setCropSrc(ev.target?.result as string)
        }
        reader.readAsDataURL(file)
        if (fileRef.current) fileRef.current.value = ''
    }

    async function handleCropConfirm(croppedDataUrl: string) {
        setCropSrc(null)
        setUploading(true)
        try {
            const res = await fetch(`http://localhost:3001/api/store/${restaurant.id}/image`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ image: croppedDataUrl }),
            })
            const data = await res.json()
            if (data.image_url) setPreviewUrl(data.image_url)
        } catch {
            alert('อัปโหลดรูปไม่สำเร็จ')
        }
        setUploading(false)
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

    useEffect(() => {
        if (state.success) dialogRef.current?.close()
    }, [state.success])

    function open() {
        dialogRef.current?.showModal()
        setTimeout(() => { window.dispatchEvent(new Event('resize')) }, 150)
    }
    function close() { if (!pending) { dialogRef.current?.close(); formRef.current?.reset() } }

    return (
        <>
            <button onClick={open} title="Edit"
                className="text-on-surface-variant hover:text-primary-container p-1 transition-colors ml-2">
                <span className="material-symbols-outlined text-[20px]">edit</span>
            </button>

            {/* Image crop modal (rendered outside dialog so it stacks above) */}
            {cropSrc && (
                <ImageCropModal
                    src={cropSrc}
                    onConfirm={handleCropConfirm}
                    onClose={() => setCropSrc(null)}
                />
            )}

            <dialog
                ref={dialogRef}
                onClick={e => { if (e.target === dialogRef.current) close() }}
                style={{ width: 'min(calc(100vw - 2rem), 36rem)' }}
                className="m-auto rounded-2xl shadow-xl p-0 bg-surface-container-lowest border-0 backdrop:bg-black/50 backdrop:backdrop-blur-sm"
            >
                {/* Header */}
                <div className="flex items-center justify-between px-6 py-4 border-b border-surface-container">
                    <div>
                        <h3 className="text-headline-sm text-on-surface">แก้ไขร้านอาหาร</h3>
                        <p className="text-body-sm text-on-surface-variant mt-0.5">{restaurant.name}</p>
                    </div>
                    <button type="button" onClick={close} disabled={pending}
                        className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <form ref={formRef} action={formAction}>
                    <input type="hidden" name="restaurantId" value={restaurant.id} />

                    <div className="px-6 py-5 flex flex-col gap-6 overflow-y-auto max-h-[65vh]">

                        {state.error && (
                            <div className="flex items-center gap-2 bg-error-container text-on-error-container text-body-sm px-4 py-3 rounded-xl">
                                <span className="material-symbols-outlined text-[18px] shrink-0">error</span>
                                {state.error}
                            </div>
                        )}

                        {/* รูปร้านอาหาร */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">รูปร้านอาหาร</p>
                            <div className="flex items-center gap-4">
                                <div className="w-20 h-20 rounded-xl overflow-hidden border border-outline-variant bg-surface-container shrink-0 flex items-center justify-center">
                                    {previewUrl ? (
                                        // eslint-disable-next-line @next/next/no-img-element
                                        <img src={previewUrl} alt="ร้าน" className="w-full h-full object-cover" />
                                    ) : (
                                        <span className="material-symbols-outlined text-on-surface-variant text-[32px]">storefront</span>
                                    )}
                                </div>
                                <div className="flex flex-col gap-2">
                                    <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={handleFileSelect} />
                                    <button type="button" disabled={uploading}
                                        onClick={() => fileRef.current?.click()}
                                        className="flex items-center gap-2 border border-outline-variant text-label-md text-on-surface px-4 py-2 rounded-full hover:bg-surface-container transition-colors disabled:opacity-50">
                                        {uploading ? (
                                            <><span className="material-symbols-outlined text-[16px] animate-spin">progress_activity</span>กำลังอัปโหลด...</>
                                        ) : (
                                            <><span className="material-symbols-outlined text-[16px]">crop</span>เลือกจากเครื่อง</>
                                        )}
                                    </button>
                                    <p className="text-body-xs text-on-surface-variant">รูปจะถูก Crop ก่อนอัปโหลด — มีปุ่ม AI Crop ช่วยตัดอัตโนมัติ</p>
                                </div>
                            </div>
                        </section>

                        {/* ข้อมูลร้านอาหาร */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">ข้อมูลร้านอาหาร</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ชื่อร้านอาหาร <span className="text-error">*</span></label>
                                    <input
                                        name="name"
                                        required
                                        className={INPUT}
                                        value={nameVal}
                                        onChange={e => setNameVal(e.target.value)}
                                    />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ประเภทอาหาร <span className="text-error">*</span></label>
                                    <div className="relative">
                                        <select
                                            name="category"
                                            required
                                            value={categoryVal}
                                            onChange={e => setCategoryVal(e.target.value)}
                                            className={INPUT + ' appearance-none pr-10'}
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
                                        placeholder="คำอธิบายร้านที่น่าสนใจ"
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
                                    <textarea name="address" rows={2} defaultValue={restaurant.address ?? ''}
                                        className={INPUT + ' resize-none'} />
                                </div>
                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="text-label-md text-on-surface mb-1.5 block">เวลาเปิด</label>
                                        <input name="open_time" type="time" defaultValue={restaurant.open_time ?? ''} className={INPUT} />
                                    </div>
                                    <div>
                                        <label className="text-label-md text-on-surface mb-1.5 block">เวลาปิด</label>
                                        <input name="close_time" type="time" defaultValue={restaurant.close_time ?? ''} className={INPUT} />
                                    </div>
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">
                                        ตำแหน่งร้าน
                                        <span className="text-body-xs text-on-surface-variant ml-2 font-normal">คลิกบนแผนที่เพื่อปักหมุด</span>
                                    </label>
                                    <div style={{ height: '220px' }} className="rounded-xl overflow-hidden border border-outline-variant">
                                        <MapPicker
                                            initialLat={restaurant.lat}
                                            initialLng={restaurant.lng}
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
                                    <input name="owner_name" defaultValue={restaurant.owner_name ?? ''} placeholder="ชื่อ-นามสกุล" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เบอร์โทรศัพท์ <span className="text-error">*</span></label>
                                    <input name="phone" type="tel" required defaultValue={restaurant.phone ?? ''} className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">อีเมล</label>
                                    <input name="email" type="email" defaultValue={restaurant.email ?? ''} className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">Line ID</label>
                                    <input name="line_id" defaultValue={restaurant.line_id ?? ''} placeholder="@lineid" className={INPUT} />
                                </div>
                            </div>
                        </section>

                        {/* บัญชีรับเงิน */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">บัญชีรับเงิน</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ธนาคาร</label>
                                    <input name="bank_name" defaultValue={restaurant.bank_name ?? ''} placeholder="เช่น กสิกรไทย, กรุงเทพ" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">ชื่อบัญชี</label>
                                    <input name="account_name" defaultValue={restaurant.account_name ?? ''} placeholder="ชื่อบัญชีธนาคาร" className={INPUT} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขบัญชี</label>
                                    <input name="account_no" defaultValue={restaurant.account_no ?? ''} placeholder="xxx-x-xxxxx-x" className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                            </div>
                        </section>

                        {/* เอกสาร */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">เอกสาร</p>
                            <div className="flex flex-col gap-4">
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขบัตรประชาชน</label>
                                    <input name="id_card" defaultValue={restaurant.id_card ?? ''} placeholder="1 xxxx xxxxx xx x" maxLength={13} className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                                <div>
                                    <label className="text-label-md text-on-surface mb-1.5 block">เลขทะเบียนพาณิชย์</label>
                                    <input name="business_license" defaultValue={restaurant.business_license ?? ''} placeholder="เลขทะเบียน (ถ้ามี)" className={INPUT + ' font-mono tracking-wider'} />
                                </div>
                            </div>
                        </section>

                        {/* สถานะ */}
                        <section>
                            <p className="text-label-sm text-on-surface-variant uppercase tracking-wider mb-3">สถานะ</p>
                            <input type="hidden" name="status" value={selectedStatus} />
                            <div className="flex gap-3">
                                {[
                                    { value: 'pending',  label: 'Pending',  desc: 'รอการอนุมัติ' },
                                    { value: 'active',   label: 'Active',   desc: 'เปิดใช้งาน' },
                                    { value: 'inactive', label: 'Inactive', desc: 'ปิดใช้งาน' },
                                ].map(opt => (
                                    <button
                                        key={opt.value}
                                        type="button"
                                        onClick={() => setSelectedStatus(opt.value)}
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
