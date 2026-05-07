'use client'

import dynamic from 'next/dynamic'

const MapPickerInner = dynamic(() => import('./MapPickerInner'), {
    ssr: false,
    loading: () => (
        <div className="w-full h-full rounded-xl bg-surface-container flex items-center justify-center">
            <span className="text-on-surface-variant text-body-sm">กำลังโหลดแผนที่...</span>
        </div>
    ),
})

type Props = {
    initialLat?: number | null
    initialLng?: number | null
    onChange: (lat: number, lng: number) => void
}

export default function MapPicker(props: Props) {
    return <MapPickerInner {...props} />
}
