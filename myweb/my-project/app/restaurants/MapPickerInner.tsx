'use client'

import { useEffect, useRef } from 'react'

type Props = {
    initialLat?: number | null
    initialLng?: number | null
    onChange: (lat: number, lng: number) => void
}

export default function MapPickerInner({ initialLat, initialLng, onChange }: Props) {
    const containerRef = useRef<HTMLDivElement>(null)
    const mapRef       = useRef<any>(null)
    const markerRef    = useRef<any>(null)
    const onChangeRef  = useRef(onChange)
    onChangeRef.current = onChange

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

            const startLat  = initialLat  ?? 13.7563
            const startLng  = initialLng  ?? 100.5018
            const startZoom = initialLat  ? 15 : 6

            const map = L.map(containerRef.current!, { zoomControl: true }).setView([startLat, startLng], startZoom)

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
                maxZoom: 19,
            }).addTo(map)

            if (initialLat && initialLng) {
                markerRef.current = L.marker([initialLat, initialLng]).addTo(map)
            }

            map.on('click', (e: any) => {
                const { lat, lng } = e.latlng
                if (markerRef.current) {
                    markerRef.current.setLatLng([lat, lng])
                } else {
                    markerRef.current = L.marker([lat, lng]).addTo(map)
                }
                onChangeRef.current(lat, lng)
            })

            mapRef.current = map

            // recalculate size after container is fully painted
            setTimeout(() => { map.invalidateSize() }, 100)
        })()

        return () => {
            mounted = false
            mapRef.current?.remove()
            mapRef.current = null
            markerRef.current = null
        }
    }, [])

    return <div ref={containerRef} style={{ height: '100%', width: '100%' }} />
}
