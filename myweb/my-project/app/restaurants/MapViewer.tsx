import dynamic from 'next/dynamic'

const MapViewerInner = dynamic(() => import('./MapViewerInner'), {
    ssr: false,
    loading: () => (
        <div className="w-full h-full bg-surface-container flex items-center justify-center">
            <span className="text-body-sm text-on-surface-variant">กำลังโหลดแผนที่...</span>
        </div>
    ),
})

export default function MapViewer({ lat, lng }: { lat: number; lng: number }) {
    return <MapViewerInner lat={lat} lng={lng} />
}
