'use client'

import { useState, useEffect } from 'react'
import { createPortal } from 'react-dom'

// ─── Types ────────────────────────────────────────────────────────────────────

type ReportKey = 'orders' | 'financials' | 'restaurants' | 'fleet'
type FormatKey = 'csv' | 'xlsx' | 'pdf' | 'pptx'
type RangeKey  = 'today' | '7d' | '30d' | 'month' | 'alltime' | 'custom'

interface Props {
  open: boolean
  onClose: () => void
}

// ─── Config ───────────────────────────────────────────────────────────────────

const REPORT_OPTIONS: { key: ReportKey; label: string; icon: string; desc: string }[] = [
  { key: 'orders',      label: 'Orders',      icon: 'receipt_long', desc: 'All order details with riders & customers'  },
  { key: 'financials',  label: 'Financial',   icon: 'payments',     desc: 'Revenue, commissions & payout breakdown'    },
  { key: 'restaurants', label: 'Restaurants', icon: 'restaurant',   desc: 'Restaurant directory and performance'       },
  { key: 'fleet',       label: 'Fleet',       icon: 'delivery_dining', desc: 'Rider roster and delivery stats'         },
]

const FORMAT_OPTIONS: { key: FormatKey; label: string; sub: string; icon: string; color: string }[] = [
  { key: 'csv',  label: 'CSV',    sub: 'ข้อมูลดิบ',         icon: 'csv',             color: 'text-tertiary' },
  { key: 'xlsx', label: 'Excel',  sub: 'ตาราง + กราฟ',      icon: 'table_chart',     color: 'text-[#217346]' },
  { key: 'pdf',  label: 'PDF',    sub: 'print dialog',      icon: 'picture_as_pdf',  color: 'text-error' },
  { key: 'pptx', label: 'Slides', sub: 'Canva / PowerPoint', icon: 'slideshow',       color: 'text-[#7C3AED]' },
]

const DATE_RANGES: { key: RangeKey; label: string }[] = [
  { key: 'today',   label: 'Today' },
  { key: '7d',      label: 'Last 7 days' },
  { key: '30d',     label: 'Last 30 days' },
  { key: 'month',   label: 'This month' },
  { key: 'alltime', label: 'All time' },
  { key: 'custom',  label: 'Custom range' },
]

// ─── Date helpers ─────────────────────────────────────────────────────────────

function getDateRange(range: RangeKey, customFrom: string, customTo: string): { from: string; to: string } {
  const now   = new Date()
  const today = now.toISOString().split('T')[0]

  const fmt = (d: Date) => d.toISOString().split('T')[0]

  switch (range) {
    case 'today':   return { from: today + ' 00:00:00',  to: today + ' 23:59:59' }
    case '7d': {
      const d = new Date(now); d.setDate(now.getDate() - 6)
      return { from: fmt(d) + ' 00:00:00', to: today + ' 23:59:59' }
    }
    case '30d': {
      const d = new Date(now); d.setDate(now.getDate() - 29)
      return { from: fmt(d) + ' 00:00:00', to: today + ' 23:59:59' }
    }
    case 'month': {
      const d = new Date(now.getFullYear(), now.getMonth(), 1)
      return { from: fmt(d) + ' 00:00:00', to: today + ' 23:59:59' }
    }
    case 'alltime': return { from: '2000-01-01 00:00:00', to: today + ' 23:59:59' }
    case 'custom':  return {
      from: (customFrom || today) + ' 00:00:00',
      to:   (customTo   || today) + ' 23:59:59',
    }
  }
}

// ─── PDF printer helper ───────────────────────────────────────────────────────

function printPDF(data: { rows: Record<string,unknown>[]; label: string; dateRange: { from:string; to:string } | null; generatedAt: string }) {
  if (!data.rows.length) return alert('No data to export as PDF.')

  const headers = Object.keys(data.rows[0])
  const dateInfo = data.dateRange
    ? `Date range: ${data.dateRange.from.split(' ')[0]} → ${data.dateRange.to.split(' ')[0]}`
    : 'All records'

  const tableRows = data.rows.map(row =>
    `<tr>${headers.map(h => `<td>${row[h] ?? ''}</td>`).join('')}</tr>`
  ).join('')

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>${data.label}</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  body { font-family: 'Segoe UI', Arial, sans-serif; font-size:11px; color:#1a1a1a; padding:20px; }
  h1 { font-size:18px; font-weight:700; color:#e25c1e; margin-bottom:4px; }
  .meta { font-size:10px; color:#666; margin-bottom:16px; }
  table { width:100%; border-collapse:collapse; }
  thead tr { background:#e25c1e; color:#fff; }
  thead th { padding:7px 10px; text-align:left; font-weight:600; white-space:nowrap; }
  tbody tr:nth-child(even) { background:#fff7f4; }
  tbody td { padding:6px 10px; border-bottom:1px solid #e8e0d8; }
  @media print {
    body { padding:10px; }
    @page { margin:15mm; }
  }
</style>
</head>
<body>
<h1>${data.label}</h1>
<p class="meta">${dateInfo} &nbsp;|&nbsp; Generated: ${new Date(data.generatedAt).toLocaleString()} &nbsp;|&nbsp; ${data.rows.length} records</p>
<table>
  <thead><tr>${headers.map(h => `<th>${h}</th>`).join('')}</tr></thead>
  <tbody>${tableRows}</tbody>
</table>
</body>
</html>`

  const win = window.open('', '_blank')
  if (!win) { alert('Please allow popups to open the PDF preview.'); return }
  win.document.write(html)
  win.document.close()
  win.onload = () => { win.print() }
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function ExportModal({ open, onClose }: Props) {
  const [report,     setReport]     = useState<ReportKey>('orders')
  const [format,     setFormat]     = useState<FormatKey>('xlsx')
  const [range,      setRange]      = useState<RangeKey>('30d')
  const [customFrom, setCustomFrom] = useState('')
  const [customTo,   setCustomTo]   = useState('')
  const [loading,    setLoading]    = useState(false)
  const [error,      setError]      = useState('')
  const [mounted,    setMounted]    = useState(false)

  useEffect(() => { setMounted(true) }, [])

  if (!open || !mounted) return null

  const needsDate = report === 'orders' || report === 'financials'

  async function handleExport() {
    setError('')
    setLoading(true)

    try {
      const { from, to } = getDateRange(range, customFrom, customTo)
      const params = new URLSearchParams({ report, format: format === 'pptx' ? 'pdf' : format, from, to })
      const res = await fetch(`/api/export?${params}`)

      if (!res.ok) {
        const j = await res.json().catch(() => ({}))
        throw new Error((j as { error?: string }).error || 'Export failed')
      }

      if (format === 'pdf') {
        const data = await res.json()
        printPDF(data)
        setLoading(false)
        return
      }

      if (format === 'pptx') {
        const data = await res.json()
        const { generatePptx } = await import('@/app/lib/generatePptx')
        await generatePptx(data, report)
        setLoading(false)
        onClose()
        return
      }

      // Download file (CSV / XLSX)
      const blob   = await res.blob()
      const url    = URL.createObjectURL(blob)
      const anchor = document.createElement('a')
      const cd     = res.headers.get('Content-Disposition') ?? ''
      const match  = cd.match(/filename="([^"]+)"/)
      anchor.href     = url
      anchor.download = match ? match[1] : `report.${format}`
      document.body.appendChild(anchor)
      anchor.click()
      document.body.removeChild(anchor)
      URL.revokeObjectURL(url)

      onClose()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Export failed')
    } finally {
      setLoading(false)
    }
  }

  return createPortal(
    <>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/40 backdrop-blur-sm"
        style={{ zIndex: 9998 }}
        onClick={onClose}
      />
      {/* Modal card — centered via transform, not flex, to avoid being clipped by sidebar transform context */}
      <div
        className="fixed bg-surface-container-lowest rounded-3xl shadow-2xl border border-outline-variant/20 overflow-hidden"
        style={{
          zIndex: 9999,
          top: '50%',
          left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 'min(calc(100vw - 2rem), 32rem)',
          maxHeight: '90vh',
          display: 'flex',
          flexDirection: 'column',
        }}
      >

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-outline-variant/20">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-primary-container/20 flex items-center justify-center text-primary">
              <span className="material-symbols-outlined">download</span>
            </div>
            <div>
              <h3 className="text-headline-sm text-on-surface">Export Reports</h3>
              <p className="text-label-sm text-on-surface-variant">Choose report, date range and format</p>
            </div>
          </div>
          <button onClick={onClose} className="text-on-surface-variant hover:text-on-surface p-1 rounded-full hover:bg-surface-container-low transition-colors">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="px-6 py-5 space-y-6 max-h-[70vh] overflow-y-auto">

          {/* Report type */}
          <div className="space-y-3">
            <p className="text-label-md font-semibold text-on-surface-variant uppercase tracking-wide">Report Type</p>
            <div className="grid grid-cols-2 gap-2">
              {REPORT_OPTIONS.map(opt => (
                <button
                  key={opt.key}
                  onClick={() => setReport(opt.key)}
                  className={`flex items-start gap-3 p-3 rounded-2xl border-2 text-left transition-all
                    ${report === opt.key
                      ? 'border-primary bg-primary-container/10'
                      : 'border-outline-variant/40 hover:border-outline-variant hover:bg-surface-container-low'}`}
                >
                  <span className={`material-symbols-outlined mt-0.5 text-[20px] ${report === opt.key ? 'text-primary' : 'text-on-surface-variant'}`}>
                    {opt.icon}
                  </span>
                  <div>
                    <p className={`text-label-md font-semibold ${report === opt.key ? 'text-primary' : 'text-on-surface'}`}>{opt.label}</p>
                    <p className="text-label-sm text-on-surface-variant leading-tight">{opt.desc}</p>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Date range — only for date-sensitive reports */}
          {needsDate && (
            <div className="space-y-3">
              <p className="text-label-md font-semibold text-on-surface-variant uppercase tracking-wide">Date Range</p>
              <div className="flex flex-wrap gap-2">
                {DATE_RANGES.map(r => (
                  <button
                    key={r.key}
                    onClick={() => setRange(r.key)}
                    className={`px-3 py-1.5 rounded-full text-label-md font-semibold border transition-all
                      ${range === r.key
                        ? 'bg-primary text-on-primary border-primary'
                        : 'border-outline-variant text-on-surface-variant hover:bg-surface-container-low'}`}
                  >
                    {r.label}
                  </button>
                ))}
              </div>
              {range === 'custom' && (
                <div className="flex gap-3 pt-1">
                  <div className="flex-1 space-y-1">
                    <label className="text-label-sm text-on-surface-variant block">From</label>
                    <input
                      type="date"
                      value={customFrom}
                      onChange={e => setCustomFrom(e.target.value)}
                      className="w-full bg-surface-container px-3 py-2 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-sm text-on-surface outline-none"
                    />
                  </div>
                  <div className="flex-1 space-y-1">
                    <label className="text-label-sm text-on-surface-variant block">To</label>
                    <input
                      type="date"
                      value={customTo}
                      onChange={e => setCustomTo(e.target.value)}
                      className="w-full bg-surface-container px-3 py-2 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-sm text-on-surface outline-none"
                    />
                  </div>
                </div>
              )}
            </div>
          )}

          {/* File format */}
          <div className="space-y-3">
            <p className="text-label-md font-semibold text-on-surface-variant uppercase tracking-wide">File Format</p>
            <div className="grid grid-cols-2 gap-2">
              {FORMAT_OPTIONS.map(f => (
                <button
                  key={f.key}
                  onClick={() => setFormat(f.key)}
                  className={`flex items-center gap-3 px-3 py-3 rounded-2xl border-2 text-left transition-all
                    ${format === f.key
                      ? 'border-primary bg-primary-container/10'
                      : 'border-outline-variant/40 hover:border-outline-variant hover:bg-surface-container-low'}`}
                >
                  <span className={`material-symbols-outlined text-[22px] shrink-0 ${format === f.key ? 'text-primary' : f.color}`}>
                    {f.icon}
                  </span>
                  <div className="min-w-0">
                    <p className={`text-label-md font-semibold leading-tight ${format === f.key ? 'text-primary' : 'text-on-surface'}`}>
                      {f.label}
                    </p>
                    <p className="text-[11px] text-on-surface-variant leading-tight mt-0.5">{f.sub}</p>
                  </div>
                  {f.key === 'pptx' && (
                    <span className="ml-auto shrink-0 text-[10px] font-bold text-[#7C3AED] bg-[#7C3AED]/10 px-1.5 py-0.5 rounded-full">
                      NEW
                    </span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Error */}
          {error && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-error-container/20 text-error text-body-sm">
              <span className="material-symbols-outlined text-[18px]">error</span>
              {error}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="flex gap-3 px-6 py-4 border-t border-outline-variant/20 bg-surface-container-low/30">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2.5 rounded-full border-2 border-outline-variant text-on-surface-variant text-label-lg font-bold hover:bg-surface-container transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleExport}
            disabled={loading}
            className="flex-1 px-4 py-2.5 rounded-full bg-primary-container text-on-primary-container text-label-lg font-bold shadow-[0_4px_12px_rgba(255,107,53,0.25)] hover:shadow-[0_6px_16px_rgba(255,107,53,0.35)] transition-shadow disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading
              ? <><span className="material-symbols-outlined animate-spin text-[18px]">progress_activity</span> Exporting…</>
              : <><span className="material-symbols-outlined text-[18px]">download</span> Export</>
            }
          </button>
        </div>
      </div>
    </>,
    document.body
  )
}
