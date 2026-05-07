'use client'

import { useEffect, useRef } from 'react'

type Props = {
    lat: number
    lng: number
}

export default function MapViewerInner({ lat, lng }: Props) {
    const containerRef = useRef<HTMLDivElement>(null)
    const mapRef       = useRef<any>(null)

    useEffect(() => {
        if (!containerRef.current || mapRef.current) return
        let mounted = true

        ;(async () => {
            const L = (await import('leaflet')).default
            if (!mounted || !containerRef.current) return

            delete (L.Icon.Default.prototype as any)._getIconUrl
            L.Icon.Default.mergeOptions({
                iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
                iconUrl:       'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
                shadowUrl:     'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
            })

            const map = L.map(containerRef.current!, {
                zoomControl: true,
                dragging: false,
                scrollWheelZoom: false,
                doubleClickZoom: false,
                touchZoom: false,
            }).setView([lat, lng], 15)

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                maxZoom: 19,
            }).addTo(map)

            L.marker([lat, lng]).addTo(map)

            mapRef.current = map
            setTimeout(() => { map.invalidateSize() }, 100)
        })()

        return () => {
            mounted = false
            mapRef.current?.remove()
            mapRef.current = null
        }
    }, [lat, lng])

    return <div ref={containerRef} style={{ height: '100%', width: '100%' }} />
}
