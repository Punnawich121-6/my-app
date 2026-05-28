'use client'

import { useState, useRef, useEffect } from 'react'

type Props = {
  initialQuery?: string
  onSelect: (proxiedUrl: string) => void
  onClose: () => void
}

export default function ImageSearchModal({ initialQuery = '', onSelect, onClose }: Props) {
  const [query, setQuery] = useState(initialQuery)
  const [pastedUrl, setPastedUrl] = useState('')
  const [previewOk, setPreviewOk] = useState(false)
  const [previewLoading, setPreviewLoading] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const urlRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  function openGoogleImages() {
    const q = encodeURIComponent((query || initialQuery).trim() + ' restaurant food')
    window.open(`https://www.google.com/search?q=${q}&tbm=isch`, '_blank')
  }

  function openUnsplash() {
    const q = encodeURIComponent((query || initialQuery).trim())
    window.open(`https://unsplash.com/s/photos/${q}`, '_blank')
  }

  function openPexels() {
    const q = encodeURIComponent((query || initialQuery).trim())
    window.open(`https://www.pexels.com/search/${q}/`, '_blank')
  }

  function handleUrlChange(url: string) {
    setPastedUrl(url)
    setPreviewOk(false)
    if (url.trim()) {
      setPreviewLoading(true)
    }
  }

  function handleConfirm() {
    if (!pastedUrl.trim() || !previewOk) return
    const proxied = `/api/image-proxy?url=${encodeURIComponent(pastedUrl.trim())}`
    onSelect(proxied)
  }

  return (
    <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-surface-container-lowest rounded-2xl shadow-2xl w-full max-w-lg flex flex-col overflow-hidden">

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-surface-container">
          <div>
            <h3 className="text-label-lg text-on-surface font-semibold">ค้นหารูปจากอินเทอร์เน็ต</h3>
            <p className="text-body-xs text-on-surface-variant mt-0.5">ค้นหาจากเว็บแล้ววางลิงค์รูปที่นี่</p>
          </div>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-surface-container text-on-surface-variant transition-colors">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="px-5 py-5 flex flex-col gap-5">

          {/* Step 1 - Search */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <span className="w-5 h-5 rounded-full bg-primary-container text-on-primary text-[11px] font-bold flex items-center justify-center shrink-0">1</span>
              <p className="text-label-md text-on-surface font-medium">ค้นหารูปจากเว็บ</p>
            </div>

            {/* Search input */}
            <div className="relative mb-3">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px]">search</span>
              <input
                ref={inputRef}
                value={query}
                onChange={e => setQuery(e.target.value)}
                onKeyDown={e => { if (e.key === 'Enter') openGoogleImages() }}
                placeholder="พิมพ์ชื่อร้านหรือประเภทอาหาร..."
                className="w-full pl-10 pr-4 py-2.5 border border-outline-variant rounded-xl text-body-md text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors"
              />
            </div>

            {/* Open browser buttons */}
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={openGoogleImages}
                className="flex flex-col items-center gap-1.5 border border-outline-variant rounded-xl py-3 px-2 hover:bg-surface-container hover:border-primary-container/40 transition-colors group"
              >
                <div className="w-8 h-8 rounded-lg bg-[#4285F4]/10 flex items-center justify-center">
                  <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                  </svg>
                </div>
                <span className="text-[11px] text-on-surface font-medium">Google Images</span>
                <span className="material-symbols-outlined text-on-surface-variant text-[12px]">open_in_new</span>
              </button>

              <button
                onClick={openUnsplash}
                className="flex flex-col items-center gap-1.5 border border-outline-variant rounded-xl py-3 px-2 hover:bg-surface-container hover:border-primary-container/40 transition-colors group"
              >
                <div className="w-8 h-8 rounded-lg bg-black/5 flex items-center justify-center">
                  <svg viewBox="0 0 32 32" className="w-5 h-5" fill="currentColor">
                    <path d="M10 9V0h12v9H10zm12 5h10v18H0V14h10v9h12v-9z"/>
                  </svg>
                </div>
                <span className="text-[11px] text-on-surface font-medium">Unsplash</span>
                <span className="material-symbols-outlined text-on-surface-variant text-[12px]">open_in_new</span>
              </button>

              <button
                onClick={openPexels}
                className="flex flex-col items-center gap-1.5 border border-outline-variant rounded-xl py-3 px-2 hover:bg-surface-container hover:border-primary-container/40 transition-colors group"
              >
                <div className="w-8 h-8 rounded-lg bg-[#05A081]/10 flex items-center justify-center">
                  <span className="text-[#05A081] font-black text-[14px]">P</span>
                </div>
                <span className="text-[11px] text-on-surface font-medium">Pexels</span>
                <span className="material-symbols-outlined text-on-surface-variant text-[12px]">open_in_new</span>
              </button>
            </div>

            <p className="text-body-xs text-on-surface-variant mt-2 text-center">
              กดเปิดเว็บ → หารูป → คลิกขวาที่รูป → <strong>คัดลอกที่อยู่รูปภาพ</strong>
            </p>
          </div>

          {/* Divider */}
          <div className="flex items-center gap-3">
            <div className="flex-1 h-px bg-outline-variant" />
            <span className="text-body-xs text-on-surface-variant">แล้ววางลิงค์ที่นี่</span>
            <div className="flex-1 h-px bg-outline-variant" />
          </div>

          {/* Step 2 - Paste URL */}
          <div>
            <div className="flex items-center gap-2 mb-3">
              <span className="w-5 h-5 rounded-full bg-primary-container text-on-primary text-[11px] font-bold flex items-center justify-center shrink-0">2</span>
              <p className="text-label-md text-on-surface font-medium">วางลิงค์รูปภาพ</p>
            </div>

            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[18px]">link</span>
              <input
                ref={urlRef}
                value={pastedUrl}
                onChange={e => handleUrlChange(e.target.value)}
                placeholder="https://images.unsplash.com/photo-..."
                className="w-full pl-10 pr-4 py-2.5 border border-outline-variant rounded-xl text-body-sm text-on-surface bg-surface focus:outline-none focus:border-primary-container focus:ring-1 focus:ring-primary-container transition-colors font-mono"
              />
            </div>

            {/* Preview */}
            {pastedUrl.trim() && (
              <div className="mt-3 rounded-xl overflow-hidden border border-outline-variant bg-surface-container" style={{ height: '160px' }}>
                {previewLoading && !previewOk && (
                  <div className="w-full h-full flex items-center justify-center gap-2 text-on-surface-variant">
                    <span className="material-symbols-outlined text-[18px] animate-spin">progress_activity</span>
                    <span className="text-body-sm">โหลดรูป...</span>
                  </div>
                )}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={`/api/image-proxy?url=${encodeURIComponent(pastedUrl.trim())}`}
                  alt="preview"
                  className={`w-full h-full object-cover transition-opacity duration-300 ${previewOk ? 'opacity-100' : 'opacity-0 absolute'}`}
                  onLoad={() => { setPreviewOk(true); setPreviewLoading(false) }}
                  onError={() => { setPreviewOk(false); setPreviewLoading(false) }}
                />
                {!previewLoading && !previewOk && pastedUrl.trim() && (
                  <div className="w-full h-full flex flex-col items-center justify-center gap-2 text-on-surface-variant">
                    <span className="material-symbols-outlined text-[32px] opacity-40">broken_image</span>
                    <span className="text-body-sm">โหลดรูปไม่ได้ — ลองลิงค์อื่น</span>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="flex gap-3 px-5 py-4 border-t border-surface-container">
          <button
            onClick={onClose}
            className="flex-1 border border-outline-variant text-on-surface text-label-md py-2.5 rounded-full hover:bg-surface-container transition-colors"
          >
            ยกเลิก
          </button>
          <button
            onClick={handleConfirm}
            disabled={!pastedUrl.trim() || !previewOk}
            className="flex-1 flex items-center justify-center gap-2 bg-primary-container text-on-primary text-label-md py-2.5 rounded-full hover:bg-primary transition-colors disabled:opacity-40"
          >
            <span className="material-symbols-outlined text-[18px]">crop</span>
            ครอปรูปนี้
          </button>
        </div>
      </div>
    </div>
  )
}
