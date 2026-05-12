'use client'

import { useEffect, useRef, useState, useTransition } from 'react'
import { seedRiderLocations } from './actions'

type RiderLoc = {
  id: string
  name: string
  status: string
  vehicle: string
  latitude: number
  longitude: number
  locationUpdatedAt: string
}

const STATUS_HEX: Record<string, string> = {
  Available:   '#22c55e',
  Busy:        '#3b82f6',
  ON_DELIVERY: '#3b82f6',
  Offline:     '#9ca3af',
  OFFLINE:     '#9ca3af',
  Pending:     '#f59e0b',
}

const VEHICLE_EMOJI: Record<string, string> = {
  motorcycle:    '🏍️',
  car:           '🚗',
  bicycle:       '🚲',
  electric_bike: '⚡',
}

function timeAgo(iso: string) {
  const sec = Math.floor((Date.now() - new Date(iso).getTime()) / 1000)
  if (sec < 60)   return `${sec} วิที่แล้ว`
  if (sec < 3600) return `${Math.floor(sec / 60)} นาทีที่แล้ว`
  return `${Math.floor(sec / 3600)} ชม.ที่แล้ว`
}

export default function RiderLiveMap() {
  const [riderCount, setRiderCount]   = useState<number | null>(null)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [apiError, setApiError]       = useState<string | null>(null)
  const [seeding, startSeed]          = useTransition()

  const containerRef   = useRef<HTMLDivElement>(null)
  const markersRef     = useRef<Record<string, any>>({})
  const fetchNowRef    = useRef<(() => void) | null>(null) // lets "ทดสอบ" button trigger fetch

  useEffect(() => {
    if (!containerRef.current) return

    let cancelled = false
    let map: any  = null
    let L: any    = null
    let interval: ReturnType<typeof setInterval>

    const updateMarkers = (riders: RiderLoc[]) => {
      if (!map || !L || cancelled) return

      const ids = new Set(riders.map(r => r.id))
      for (const id of Object.keys(markersRef.current)) {
        if (!ids.has(id)) { markersRef.current[id].remove(); delete markersRef.current[id] }
      }

      for (const rider of riders) {
        const color = STATUS_HEX[rider.status] ?? '#9ca3af'
        const emoji = VEHICLE_EMOJI[rider.vehicle] ?? '🏍️'
        const icon  = L.divIcon({
          className: '',
          html: `<div style="width:36px;height:36px;background:${color};border:3px solid #fff;
                   border-radius:50%;box-shadow:0 2px 8px rgba(0,0,0,.35);
                   display:flex;align-items:center;justify-content:center;
                   font-size:16px;cursor:pointer;">${emoji}</div>`,
          iconSize:   [36, 36],
          iconAnchor: [18, 18],
        })

        const popup = `<div style="font-family:sans-serif;min-width:150px;padding:2px">
          <b style="font-size:14px">${rider.name}</b>
          <div style="font-size:12px;color:#555;margin-top:3px">${rider.vehicle} · ${rider.status}</div>
          <div style="font-size:11px;color:#999;margin-top:4px">📍 ${timeAgo(rider.locationUpdatedAt)}</div>
        </div>`

        if (markersRef.current[rider.id]) {
          markersRef.current[rider.id]
            .setLatLng([rider.latitude, rider.longitude])
            .setIcon(icon)
            .getPopup()?.setContent(popup)
        } else {
          markersRef.current[rider.id] = L.marker([rider.latitude, rider.longitude], { icon })
            .bindPopup(popup)
            .addTo(map)
        }
      }

      const all = Object.values(markersRef.current)
      if (all.length > 0) {
        try { map.fitBounds(L.featureGroup(all).getBounds().pad(0.2)) } catch (_) {}
      }

      setRiderCount(riders.length)
      setLastUpdated(new Date())
      setApiError(null)
    }

    const fetchAndUpdate = async () => {
      if (cancelled) return
      try {
        const res = await fetch('/api/rider-locations', { cache: 'no-store' })
        if (cancelled) return
        if (!res.ok) {
          const body = await res.json().catch(() => ({}))
          setApiError(body.error ?? `HTTP ${res.status}`)
          return
        }
        updateMarkers(await res.json())
      } catch (e: any) {
        if (!cancelled) setApiError(e.message)
      }
    }

    // Expose so the seed button can trigger an immediate refresh
    fetchNowRef.current = fetchAndUpdate

    const init = async () => {
      if (!document.getElementById('leaflet-css')) {
        const link = document.createElement('link')
        link.id    = 'leaflet-css'
        link.rel   = 'stylesheet'
        link.href  = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css'
        document.head.appendChild(link)
      }

      const mod = await import('leaflet')
      if (cancelled) return

      L = (mod as any).default ?? mod
      delete (L.Icon.Default.prototype as any)._getIconUrl
      L.Icon.Default.mergeOptions({
        iconUrl:       'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
        iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
        shadowUrl:     'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
      })

      map = L.map(containerRef.current!, { zoomControl: true })
        .setView([13.7563, 100.5018], 11)
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        maxZoom: 19,
      }).addTo(map)

      await fetchAndUpdate()
      if (cancelled) return
      interval = setInterval(fetchAndUpdate, 15_000)
    }

    init()

    return () => {
      cancelled = true
      clearInterval(interval)
      fetchNowRef.current = null
      if (map) { map.remove(); map = null }
      markersRef.current = {}
    }
  }, [])

  const handleSeed = () => {
    startSeed(async () => {
      await seedRiderLocations()
      // Give the DB a moment then refresh markers
      setTimeout(() => fetchNowRef.current?.(), 300)
    })
  }

  const isEmpty  = riderCount === 0
  const isLoading = riderCount === null && !apiError

  return (
    <div className="mb-8 rounded-xl overflow-hidden border border-surface-variant shadow-sm">

      {/* ── Header ── */}
      <div className="flex items-center justify-between px-6 py-4 bg-surface-container-lowest border-b border-surface-variant flex-wrap gap-3">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary-container/20 rounded-lg">
            <span className="material-symbols-outlined text-primary">location_on</span>
          </div>
          <div>
            <h3 className="text-label-lg text-on-surface font-semibold">Live Rider Map</h3>
            <p className="text-body-xs text-on-surface-variant mt-0.5">
              ตำแหน่งไรเดอร์แบบ real-time · อัปเดตทุก 15 วินาที
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {lastUpdated && (
            <span className="text-label-xs text-on-surface-variant hidden sm:block">
              อัปเดต {lastUpdated.toLocaleTimeString('th-TH')}
            </span>
          )}
          {riderCount !== null && riderCount > 0 && (
            <span className="bg-green-100 text-green-700 text-label-sm px-2.5 py-1 rounded-full font-semibold">
              {riderCount} ไรเดอร์
            </span>
          )}
          <button
            onClick={handleSeed}
            disabled={seeding}
            className="flex items-center gap-1.5 px-3 py-1.5 text-label-sm border border-outline-variant text-on-surface-variant rounded-full hover:bg-surface-container transition-colors disabled:opacity-50"
            title="ใส่ตำแหน่งทดสอบ Bangkok สำหรับ riders ที่มีอยู่"
          >
            <span className="material-symbols-outlined text-[14px]">
              {seeding ? 'hourglass_empty' : 'science'}
            </span>
            {seeding ? 'กำลังใส่...' : 'ทดสอบ'}
          </button>
          <span className="flex items-center gap-1.5 text-label-sm text-on-surface-variant">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse inline-block" />
            LIVE
          </span>
        </div>
      </div>

      {/* ── Error ── */}
      {apiError && (
        <div className="px-6 py-3 bg-red-50 border-b border-red-100 text-body-sm text-red-700 flex items-center gap-2">
          <span className="material-symbols-outlined text-[16px]">error</span>
          {apiError}
        </div>
      )}

      {/* ── Map + overlays ── */}
      <div className="relative">
        {/* Leaflet mounts here — must not have children that Leaflet would overwrite */}
        <div ref={containerRef} style={{ height: 420 }} className="w-full" />

        {/* Loading overlay — on top of map container */}
        {isLoading && (
          <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 bg-surface-container text-on-surface-variant" style={{ zIndex: 500 }}>
            <span className="material-symbols-outlined text-4xl" style={{ animation: 'spin 1.5s linear infinite' }}>sync</span>
            <p className="text-body-sm">กำลังโหลดแผนที่...</p>
            <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
          </div>
        )}

        {/* No-riders overlay — floats over the rendered map */}
        {isEmpty && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none" style={{ zIndex: 500 }}>
            <div style={{ width: 280, background: 'rgba(255,255,255,0.95)', backdropFilter: 'blur(6px)', borderRadius: 20, padding: '20px 24px', boxShadow: '0 8px 32px rgba(0,0,0,0.18)', textAlign: 'center', pointerEvents: 'auto' }}>
              <span className="material-symbols-outlined text-3xl text-amber-500" style={{ display: 'block', marginBottom: 8 }}>location_searching</span>
              <p style={{ fontSize: 14, fontWeight: 600, color: '#1a1a1a', marginBottom: 6 }}>ยังไม่มีไรเดอร์แชร์ตำแหน่ง</p>
              <p style={{ fontSize: 12, color: '#666', lineHeight: 1.6, marginBottom: 4 }}>
                เปิดแอพไรเดอร์แล้วอนุญาต GPS เพื่อให้จุดปรากฏบนแผนที่
              </p>
              <p style={{ fontSize: 12, color: '#666', lineHeight: 1.6 }}>
                หรือกด <b>ทดสอบ</b> เพื่อดูตำแหน่งจำลอง
              </p>
            </div>
          </div>
        )}
      </div>

      {/* ── Legend ── */}
      <div className="flex flex-wrap items-center gap-4 px-6 py-3 bg-surface-bright border-t border-surface-variant">
        {[
          { cls: 'bg-green-500', label: 'Available' },
          { cls: 'bg-blue-500',  label: 'Busy / On Delivery' },
          { cls: 'bg-slate-400', label: 'Offline' },
          { cls: 'bg-amber-500', label: 'Pending' },
        ].map(({ cls, label }) => (
          <span key={label} className="flex items-center gap-1.5 text-label-sm text-on-surface-variant">
            <span className={`w-3 h-3 rounded-full ${cls}`} />
            {label}
          </span>
        ))}
        <span className="ml-auto text-label-xs text-on-surface-variant hidden sm:block">
          คลิกที่ไอคอนเพื่อดูรายละเอียดไรเดอร์
        </span>
      </div>
    </div>
  )
}
