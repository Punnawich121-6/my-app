'use client'

import { useState, useRef, useEffect, useCallback } from 'react'
import { createPortal } from 'react-dom'
import { usePathname } from 'next/navigation'

type Message = { role: 'user' | 'assistant'; content: string }

const SUGGESTIONS = [
  'ยอดขายวันนี้เป็นอย่างไร?',
  'แนะนำกลยุทธ์เพิ่มยอดขาย',
  'ร้านไหนทำผลงานดีที่สุด?',
  'วิธีลดออเดอร์ที่ยกเลิก',
]

const Z = 999999
const BTN_SIZE = 56
const PANEL_W = 360
const PANEL_H = 480
const MARGIN = 16

function clamp(val: number, min: number, max: number) {
  return Math.min(Math.max(val, min), max)
}

function getInitialPos() {
  if (typeof window === 'undefined') return { x: 0, y: 0 }
  try {
    const saved = localStorage.getItem('ai-widget-pos')
    if (saved) {
      const p = JSON.parse(saved)
      return {
        x: clamp(p.x, MARGIN, window.innerWidth - BTN_SIZE - MARGIN),
        y: clamp(p.y, MARGIN, window.innerHeight - BTN_SIZE - MARGIN),
      }
    }
  } catch {}
  return {
    x: window.innerWidth - BTN_SIZE - 24,
    y: window.innerHeight - BTN_SIZE - 24,
  }
}

export default function AIChatWidget() {
  const pathname = usePathname()
  const [open, setOpen]         = useState(false)
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput]       = useState('')
  const [streaming, setStreaming] = useState(false)
  const [mounted, setMounted]   = useState(false)
  const [pos, setPos]           = useState({ x: 0, y: 0 })
  const bottomRef  = useRef<HTMLDivElement>(null)
  const inputRef   = useRef<HTMLInputElement>(null)
  const dragRef    = useRef<{ startX: number; startY: number; origX: number; origY: number; moved: boolean } | null>(null)

  useEffect(() => {
    setPos(getInitialPos())
    setMounted(true)
  }, [])

  useEffect(() => {
    if (open && messages.length === 0) {
      setMessages([{
        role: 'assistant',
        content: 'สวัสดีครับ! ผมคือ AI ผู้ช่วยของ Zest & Savory 🍽️\nสามารถถามผมเกี่ยวกับยอดขาย, ออเดอร์, ร้านอาหาร หรือขอคำแนะนำธุรกิจได้เลยครับ',
      }])
    }
    if (open) setTimeout(() => inputRef.current?.focus(), 100)
  }, [open, messages.length])

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages, streaming])

  // ── Drag logic ──
  const onMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault()
    dragRef.current = { startX: e.clientX, startY: e.clientY, origX: pos.x, origY: pos.y, moved: false }

    function onMove(ev: MouseEvent) {
      if (!dragRef.current) return
      const dx = ev.clientX - dragRef.current.startX
      const dy = ev.clientY - dragRef.current.startY
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) dragRef.current.moved = true
      if (!dragRef.current.moved) return

      const nx = clamp(dragRef.current.origX + dx, MARGIN, window.innerWidth  - BTN_SIZE - MARGIN)
      const ny = clamp(dragRef.current.origY + dy, MARGIN, window.innerHeight - BTN_SIZE - MARGIN)
      setPos({ x: nx, y: ny })
    }

    function onUp(ev: MouseEvent) {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup',   onUp)
      if (!dragRef.current) return
      const moved = dragRef.current.moved
      dragRef.current = null
      if (!moved) {
        setOpen(v => !v)
      } else {
        // save final position
        setPos(p => {
          try { localStorage.setItem('ai-widget-pos', JSON.stringify(p)) } catch {}
          return p
        })
      }
    }

    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup',   onUp)
  }, [pos])

  // Touch support
  const onTouchStart = useCallback((e: React.TouchEvent) => {
    const t = e.touches[0]
    dragRef.current = { startX: t.clientX, startY: t.clientY, origX: pos.x, origY: pos.y, moved: false }

    function onMove(ev: TouchEvent) {
      if (!dragRef.current) return
      const touch = ev.touches[0]
      const dx = touch.clientX - dragRef.current.startX
      const dy = touch.clientY - dragRef.current.startY
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) dragRef.current.moved = true
      if (!dragRef.current.moved) return
      ev.preventDefault()

      const nx = clamp(dragRef.current.origX + dx, MARGIN, window.innerWidth  - BTN_SIZE - MARGIN)
      const ny = clamp(dragRef.current.origY + dy, MARGIN, window.innerHeight - BTN_SIZE - MARGIN)
      setPos({ x: nx, y: ny })
    }

    function onEnd() {
      window.removeEventListener('touchmove', onMove)
      window.removeEventListener('touchend',  onEnd)
      if (!dragRef.current) return
      const moved = dragRef.current.moved
      dragRef.current = null
      if (!moved) {
        setOpen(v => !v)
      } else {
        setPos(p => {
          try { localStorage.setItem('ai-widget-pos', JSON.stringify(p)) } catch {}
          return p
        })
      }
    }

    window.addEventListener('touchmove', onMove, { passive: false })
    window.addEventListener('touchend',  onEnd)
  }, [pos])

  // ── Panel position: open above/below and left/right based on available space ──
  function getPanelStyle(): React.CSSProperties {
    const spaceBelow = window.innerHeight - (pos.y + BTN_SIZE)
    const spaceRight = window.innerWidth  - pos.x

    const top = spaceBelow >= PANEL_H + MARGIN
      ? pos.y + BTN_SIZE + 8
      : pos.y - PANEL_H - 8

    const left = spaceRight >= PANEL_W + MARGIN
      ? pos.x
      : pos.x - PANEL_W + BTN_SIZE

    return {
      position: 'fixed',
      top:  clamp(top,  MARGIN, window.innerHeight - PANEL_H - MARGIN),
      left: clamp(left, MARGIN, window.innerWidth  - PANEL_W - MARGIN),
      width: PANEL_W,
      maxWidth: `calc(100vw - ${MARGIN * 2}px)`,
      height: PANEL_H,
      zIndex: Z,
    }
  }

  async function send(text?: string) {
    const content = (text ?? input).trim()
    if (!content || streaming) return
    setInput('')

    const newMessages: Message[] = [...messages, { role: 'user', content }]
    setMessages(newMessages)
    setStreaming(true)
    setMessages(prev => [...prev, { role: 'assistant', content: '' }])

    try {
      const res = await fetch('/api/ai/chat', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          messages: newMessages.map(m => ({ role: m.role, content: m.content })),
        }),
      })

      if (!res.ok || !res.body) {
        setMessages(prev => [...prev.slice(0, -1), { role: 'assistant', content: 'เกิดข้อผิดพลาด กรุณาลองใหม่' }])
        setStreaming(false)
        return
      }

      const reader = res.body.getReader()
      const dec = new TextDecoder()
      let buf = ''
      let assembled = ''

      while (true) {
        const { done, value } = await reader.read()
        if (done) break
        buf += dec.decode(value, { stream: true })
        const lines = buf.split('\n')
        buf = lines.pop() ?? ''
        for (const line of lines) {
          if (!line.startsWith('data:')) continue
          const raw = line.slice(5).trim()
          if (raw === '[DONE]') continue
          try {
            const evt = JSON.parse(raw)
            if (evt.text) {
              assembled += evt.text
              setMessages(prev => [...prev.slice(0, -1), { role: 'assistant', content: assembled }])
            }
          } catch { /* skip */ }
        }
      }
    } catch (e: any) {
      setMessages(prev => [...prev.slice(0, -1), { role: 'assistant', content: 'เกิดข้อผิดพลาด: ' + e.message }])
    } finally {
      setStreaming(false)
    }
  }

  function formatMsg(text: string) {
    return text
      .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
      .replace(/\n/g, '<br/>')
  }

  if (!mounted || pathname === '/login') return null

  return createPortal(
    <>
      {/* FAB — draggable */}
      <button
        onMouseDown={onMouseDown}
        onTouchStart={onTouchStart}
        style={{ position: 'fixed', left: pos.x, top: pos.y, zIndex: Z + 1, cursor: 'grab', touchAction: 'none' }}
        className="w-14 h-14 rounded-full bg-primary-container text-on-primary shadow-xl flex items-center justify-center hover:bg-primary transition-colors active:cursor-grabbing select-none"
        title="AI Assistant — กดค้างเพื่อย้าย"
      >
        <span className="material-symbols-outlined text-[26px] pointer-events-none">
          {open ? 'close' : 'smart_toy'}
        </span>
      </button>

      {/* Chat panel */}
      {open && (
        <div
          style={getPanelStyle()}
          className="bg-surface-container-lowest rounded-2xl shadow-2xl border border-surface-container flex flex-col overflow-hidden"
        >
          {/* Header */}
          <div className="flex items-center gap-3 px-4 py-3 border-b border-surface-container bg-primary-container/5 shrink-0">
            <div className="w-9 h-9 rounded-full bg-primary-container flex items-center justify-center shrink-0">
              <span className="material-symbols-outlined text-on-primary text-[18px]">smart_toy</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-label-md text-on-surface font-semibold">AI ผู้ช่วยธุรกิจ</p>
              <p className="text-body-xs text-green-600 flex items-center gap-1">
                <span className="w-1.5 h-1.5 bg-green-500 rounded-full inline-block" />
                Online
              </p>
            </div>
            <button
              onClick={() => { setMessages([]); setOpen(false) }}
              className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container transition-colors"
            >
              <span className="material-symbols-outlined text-[18px]">close</span>
            </button>
          </div>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-4 py-3 flex flex-col gap-3 min-h-0">
            {messages.map((m, i) => (
              <div key={i} className={`flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                {m.role === 'assistant' && (
                  <div className="w-6 h-6 rounded-full bg-primary-container/20 flex items-center justify-center shrink-0 mr-2 mt-0.5">
                    <span className="material-symbols-outlined text-primary-container text-[13px]">smart_toy</span>
                  </div>
                )}
                <div
                  className={`max-w-[80%] px-3 py-2 rounded-2xl text-body-sm leading-relaxed ${
                    m.role === 'user'
                      ? 'bg-primary-container text-on-primary rounded-tr-sm'
                      : 'bg-surface-container text-on-surface rounded-tl-sm'
                  }`}
                >
                  {m.content === '' && streaming ? (
                    <span className="flex gap-1 items-center py-0.5">
                      <span className="w-1.5 h-1.5 bg-on-surface-variant rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                      <span className="w-1.5 h-1.5 bg-on-surface-variant rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                      <span className="w-1.5 h-1.5 bg-on-surface-variant rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                    </span>
                  ) : (
                    <span dangerouslySetInnerHTML={{ __html: formatMsg(m.content) }} />
                  )}
                </div>
              </div>
            ))}
            <div ref={bottomRef} />
          </div>

          {/* Suggestions */}
          {messages.length === 1 && (
            <div className="px-4 pb-2 flex flex-wrap gap-1.5 shrink-0">
              {SUGGESTIONS.map(s => (
                <button
                  key={s}
                  onClick={() => send(s)}
                  className="text-body-xs text-primary-container bg-primary-container/10 border border-primary-container/20 px-2.5 py-1 rounded-full hover:bg-primary-container/20 transition-colors"
                >
                  {s}
                </button>
              ))}
            </div>
          )}

          {/* Input */}
          <div className="flex items-center gap-2 px-3 py-3 border-t border-surface-container shrink-0">
            <input
              ref={inputRef}
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send() } }}
              placeholder="พิมพ์คำถามที่นี่..."
              disabled={streaming}
              className="flex-1 bg-surface-container rounded-full px-4 py-2 text-body-sm text-on-surface placeholder:text-on-surface-variant focus:outline-none focus:ring-1 focus:ring-primary-container disabled:opacity-60"
            />
            <button
              onClick={() => send()}
              disabled={!input.trim() || streaming}
              className="w-9 h-9 rounded-full bg-primary-container text-on-primary flex items-center justify-center hover:bg-primary transition-colors disabled:opacity-40"
            >
              <span className="material-symbols-outlined text-[18px]">send</span>
            </button>
          </div>
        </div>
      )}
    </>,
    document.body
  )
}
