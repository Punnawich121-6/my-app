'use client'

import { useEffect, useRef, useState } from 'react'

type Props = {
  src: string
  onConfirm: (croppedDataUrl: string) => void
  onClose: () => void
}

type AiCrop = { x: number; y: number; w: number; h: number }

type Crop = { x: number; y: number; w: number; h: number }
type Handle = 'move' | 'tl' | 'tr' | 'bl' | 'br'

const MIN = 60
const ORANGE = '#FF6B35'

const HANDLES: { id: Handle; style: React.CSSProperties; cursor: string }[] = [
  { id: 'tl', style: { top: -14, left: -14 },     cursor: 'nwse-resize' },
  { id: 'tr', style: { top: -14, right: -14 },    cursor: 'nesw-resize' },
  { id: 'bl', style: { bottom: -14, left: -14 },  cursor: 'nesw-resize' },
  { id: 'br', style: { bottom: -14, right: -14 }, cursor: 'nwse-resize' },
]

export default function ImageCropModal({ src, onConfirm, onClose }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null)
  const imgRef    = useRef<HTMLImageElement>(null)
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const [crop, setCrop]           = useState<Crop>({ x: 0, y: 0, w: 200, h: 200 })
  const [imgLoaded, setImgLoaded] = useState(false)
  const [activeHandle, setActiveHandle] = useState<Handle | null>(null)
  const dragStart = useRef<{ mx: number; my: number; crop: Crop } | null>(null)
  const [aiLoading, setAiLoading] = useState(false)
  const [aiStatus, setAiStatus]   = useState<'idle' | 'ok' | 'fail'>('idle')

  // Open as top-layer modal so it sits above any other <dialog>
  useEffect(() => {
    const el = dialogRef.current
    if (!el) return
    if (!el.open) el.showModal()
    return () => { try { el.close() } catch { /* already closed */ } }
  }, [])

  function initCrop(img: HTMLImageElement) {
    const sx = img.offsetWidth / img.naturalWidth
    const sy = img.offsetHeight / img.naturalHeight
    const scale = Math.min(sx, sy)
    const dispW = img.naturalWidth * scale
    const dispH = img.naturalHeight * scale
    const size  = Math.round(Math.min(dispW, dispH) * 0.8)
    setCrop({
      x: Math.round((img.offsetWidth  - size) / 2),
      y: Math.round((img.offsetHeight - size) / 2),
      w: size, h: size,
    })
    setImgLoaded(true)
  }

  function onImgLoad() { if (imgRef.current) initCrop(imgRef.current) }
  useEffect(() => { if (imgRef.current?.complete) onImgLoad() }, [src]) // eslint-disable-line react-hooks/exhaustive-deps

  function clamp(c: Crop, maxW: number, maxH: number): Crop {
    const w = Math.max(MIN, Math.min(c.w, maxW))
    const h = Math.max(MIN, Math.min(c.h, maxH))
    return { w, h, x: Math.max(0, Math.min(c.x, maxW - w)), y: Math.max(0, Math.min(c.y, maxH - h)) }
  }

  function xy(e: React.MouseEvent | React.TouchEvent) {
    if ('touches' in e) return { x: e.touches[0].clientX, y: e.touches[0].clientY }
    return { x: e.clientX, y: e.clientY }
  }

  function startHandle(e: React.MouseEvent | React.TouchEvent, handle: Handle) {
    e.preventDefault(); e.stopPropagation()
    const { x, y } = xy(e)
    setActiveHandle(handle)
    dragStart.current = { mx: x, my: y, crop: { ...crop } }
  }

  useEffect(() => {
    function onMove(e: MouseEvent | TouchEvent) {
      const img = imgRef.current
      if (!img || !activeHandle || !dragStart.current) return
      const cx = 'touches' in e ? (e as TouchEvent).touches[0]?.clientX ?? 0 : (e as MouseEvent).clientX
      const cy = 'touches' in e ? (e as TouchEvent).touches[0]?.clientY ?? 0 : (e as MouseEvent).clientY
      const dx = cx - dragStart.current.mx
      const dy = cy - dragStart.current.my
      const { x, y, w, h } = dragStart.current.crop
      let next: Crop
      if      (activeHandle === 'move') next = { x: x+dx, y: y+dy, w, h }
      else if (activeHandle === 'tl')   next = { x: x+dx, y: y+dy, w: w-dx, h: h-dy }
      else if (activeHandle === 'tr')   next = { x,       y: y+dy, w: w+dx, h: h-dy }
      else if (activeHandle === 'bl')   next = { x: x+dx, y,       w: w-dx, h: h+dy }
      else                              next = { x,       y,       w: w+dx, h: h+dy }
      setCrop(clamp(next, img.offsetWidth, img.offsetHeight))
    }
    function onUp() { setActiveHandle(null) }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    window.addEventListener('touchmove', onMove, { passive: false })
    window.addEventListener('touchend', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
      window.removeEventListener('touchmove', onMove)
      window.removeEventListener('touchend', onUp)
    }
  }, [activeHandle])

  function resetCrop() {
    const img = imgRef.current; if (!img) return
    const sx = img.offsetWidth / img.naturalWidth
    const sy = img.offsetHeight / img.naturalHeight
    const scale = Math.min(sx, sy)
    const size  = Math.round(Math.min(img.naturalWidth * scale, img.naturalHeight * scale) * 0.85)
    setCrop({ x: Math.round((img.offsetWidth - size) / 2), y: Math.round((img.offsetHeight - size) / 2), w: size, h: size })
  }

  async function autoCrop() {
    const img = imgRef.current; if (!img) return
    setAiLoading(true); setAiStatus('idle')
    try {
      const res = await fetch('/api/ai/crop', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ image: src }),
        signal: AbortSignal.timeout(25000),
      })
      const ai: AiCrop = await res.json()
      // AI returns normalized coords (0-1) relative to natural image size.
      // Convert to display pixel coords matching the existing crop box coordinate system.
      const sx = img.offsetWidth / img.naturalWidth
      const sy = img.offsetHeight / img.naturalHeight
      const scale = Math.min(sx, sy)
      // Actual rendered image content size (may be letterboxed inside container)
      const dispW = img.naturalWidth  * scale
      const dispH = img.naturalHeight * scale
      // Offset of image content within the container (centered)
      const offX = (img.offsetWidth  - dispW) / 2
      const offY = (img.offsetHeight - dispH) / 2
      const newCrop: Crop = {
        x: Math.round(offX + ai.x * dispW),
        y: Math.round(offY + ai.y * dispH),
        w: Math.round(ai.w * dispW),
        h: Math.round(ai.h * dispH),
      }
      setCrop(clamp(newCrop, img.offsetWidth, img.offsetHeight))
      setAiStatus('ok')
    } catch {
      setAiStatus('fail')
    }
    setAiLoading(false)
  }

  function confirmCrop() {
    const img = imgRef.current; const canvas = canvasRef.current
    if (!img || !canvas) return
    const OUT = 800; canvas.width = OUT; canvas.height = OUT
    const ctx = canvas.getContext('2d')!
    // objectFit:contain may letterbox — compute actual rendered image bounds
    const scale = Math.min(img.offsetWidth / img.naturalWidth, img.offsetHeight / img.naturalHeight)
    const offX = (img.offsetWidth  - img.naturalWidth  * scale) / 2
    const offY = (img.offsetHeight - img.naturalHeight * scale) / 2
    const natX = (crop.x - offX) / scale
    const natY = (crop.y - offY) / scale
    const natW = crop.w / scale
    const natH = crop.h / scale
    ctx.drawImage(img, natX, natY, natW, natH, 0, 0, OUT, OUT)
    onConfirm(canvas.toDataURL('image/jpeg', 0.92))
  }

  return (
    <dialog
      ref={dialogRef}
      onCancel={e => { e.preventDefault(); onClose() }}
      style={{
        padding: 0, margin: 0, border: 'none', background: '#000',
        width: '100vw', height: '100vh', maxWidth: '100vw', maxHeight: '100vh',
        display: 'flex', flexDirection: 'column',
      }}
    >
      {/* Top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '12px 16px', background: 'rgba(0,0,0,0.9)', borderBottom: '1px solid rgba(255,255,255,0.1)', flexShrink: 0 }}>
        <button onClick={onClose} style={{ padding: 8, borderRadius: '50%', background: 'transparent', border: 'none', cursor: 'pointer', color: '#fff', display: 'flex', alignItems: 'center' }}>
          <span className="material-symbols-outlined" style={{ fontSize: 24 }}>close</span>
        </button>
        <span style={{ color: '#fff', fontWeight: 600, fontSize: 16 }}>Crop รูปร้าน</span>
        <button onClick={confirmCrop} style={{ padding: '8px 20px', borderRadius: 999, background: ORANGE, border: 'none', cursor: 'pointer', color: '#fff', fontWeight: 700, fontSize: 14 }}>
          ยืนยัน
        </button>
      </div>

      {/* Crop area */}
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', userSelect: 'none' }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img ref={imgRef} src={src} alt="crop" onLoad={onImgLoad} draggable={false}
          style={{ width: '100%', height: '100%', objectFit: 'contain', display: 'block' }} />

        {imgLoaded && (
          <>
            {/* Dark overlay */}
            <div style={{
              position: 'absolute', inset: 0, pointerEvents: 'none',
              boxShadow: `0 0 0 9999px rgba(0,0,0,0.6)`,
              clipPath: `polygon(0% 0%,0% 100%,${crop.x}px 100%,${crop.x}px ${crop.y}px,${crop.x+crop.w}px ${crop.y}px,${crop.x+crop.w}px ${crop.y+crop.h}px,${crop.x}px ${crop.y+crop.h}px,${crop.x}px 100%,100% 100%,100% 0%)`,
            }} />

            {/* Crop box */}
            <div
              onMouseDown={e => startHandle(e, 'move')}
              onTouchStart={e => startHandle(e, 'move')}
              style={{ position: 'absolute', left: crop.x, top: crop.y, width: crop.w, height: crop.h, border: '1.5px solid #fff', cursor: 'move', boxSizing: 'border-box' }}
            >
              {/* Grid */}
              {[33, 66].map(p => <div key={'v'+p} style={{ position:'absolute', top:0, bottom:0, left:`${p}%`, borderRight:'1px solid rgba(255,255,255,0.3)', pointerEvents:'none' }} />)}
              {[33, 66].map(p => <div key={'h'+p} style={{ position:'absolute', left:0, right:0, top:`${p}%`, borderBottom:'1px solid rgba(255,255,255,0.3)', pointerEvents:'none' }} />)}

              {/* Corner handles */}
              {HANDLES.map(({ id, style, cursor }) => (
                <div key={id}
                  onMouseDown={e => startHandle(e, id)}
                  onTouchStart={e => startHandle(e, id)}
                  style={{ position:'absolute', width:28, height:28, borderRadius:'50%', background:ORANGE, border:'2.5px solid #fff', boxShadow:'0 2px 8px rgba(0,0,0,0.4)', cursor, zIndex:10, ...style }}
                />
              ))}
            </div>
          </>
        )}
      </div>

      {/* Bottom */}
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:10, padding:'14px 16px 28px', flexShrink:0 }}>
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <button
            onClick={autoCrop}
            disabled={aiLoading}
            style={{ display:'flex', alignItems:'center', gap:6, padding:'7px 18px', borderRadius:999, background: aiLoading ? 'rgba(255,107,53,0.3)' : ORANGE, border:'none', cursor: aiLoading ? 'not-allowed' : 'pointer', color:'#fff', fontSize:13, fontWeight:600, transition:'background 0.2s' }}
          >
            <span className={`material-symbols-outlined${aiLoading ? ' animate-spin' : ''}`} style={{ fontSize:16 }}>
              {aiLoading ? 'progress_activity' : 'auto_awesome'}
            </span>
            {aiLoading ? 'AI กำลังวิเคราะห์...' : 'AI Crop'}
          </button>
          <button onClick={resetCrop} style={{ padding:'7px 16px', borderRadius:999, background:'rgba(255,255,255,0.12)', border:'1px solid rgba(255,255,255,0.25)', cursor:'pointer', color:'#fff', fontSize:12, fontWeight:500 }}>
            รีเซ็ต
          </button>
        </div>
        {aiStatus === 'ok'   && <span style={{ color:'#4ade80', fontSize:11 }}>✓ AI crop สำเร็จ — ปรับเพิ่มเติมได้ตามต้องการ</span>}
        {aiStatus === 'fail' && <span style={{ color:'#f87171', fontSize:11 }}>AI ไม่สามารถวิเคราะห์ได้ — ลองปรับ crop เอง</span>}
        {aiStatus === 'idle' && <span style={{ color:'rgba(255,255,255,0.55)', fontSize:11 }}>ลากมุมสีส้มเพื่อปรับขนาด • ลากกล่องเพื่อย้าย</span>}
      </div>

      <canvas ref={canvasRef} style={{ display:'none' }} />
    </dialog>
  )
}
