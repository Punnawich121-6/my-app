'use client'

import { useState, useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'

type QuarterlySummary = {
  year: number; quarter: number; revenue: number; orderCount: number; avgOrderValue: number; restaurantCount: number
}
type MonthlyData = { month: number; monthName: string; revenue: number; orderCount: number }
type CategoryData = { category: string; revenue: number; orderCount: number; share: number }
type CurrentSummary = { revenue: number; orderCount: number; avgOrderValue: number; restaurantCount: number }

type Props = {
  history: QuarterlySummary[]
  initialYear: number
  initialMonth: number
}

const CARD = "bg-surface-container-lowest rounded-2xl border border-surface-container shadow-sm p-6"
const BAR_COLORS = ['bg-primary-container', 'bg-[#f97316]', 'bg-[#22c55e]', 'bg-[#a855f7]', 'bg-[#06b6d4]', 'bg-[#ec4899]', 'bg-[#eab308]', 'bg-[#64748b]']

const MONTH_ABBR = ['', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.']

type PlanPeriod = 1 | 2 | 3 | 6 | 12

function getPeriods(planPeriod: PlanPeriod): Array<{ label: string; startMonth: number; endMonth: number }> {
  if (planPeriod === 12) {
    return [
      { label: 'ทั้งปี', startMonth: 1, endMonth: 12 },
      ...Array.from({ length: 12 }, (_, i) => ({ label: MONTH_ABBR[i + 1], startMonth: i + 1, endMonth: i + 1 })),
    ]
  }
  const periods: Array<{ label: string; startMonth: number; endMonth: number }> = []
  for (let m = 1; m <= 12; m += planPeriod) {
    const endM = Math.min(m + planPeriod - 1, 12)
    const label = planPeriod === 1 ? MONTH_ABBR[m] : `${MONTH_ABBR[m]}–${MONTH_ABBR[endM]}`
    periods.push({ label, startMonth: m, endMonth: endM })
  }
  return periods
}

function findPeriod(planPeriod: PlanPeriod, month: number) {
  if (planPeriod === 12) return { label: 'ทั้งปี', startMonth: 1, endMonth: 12 }
  const list = getPeriods(planPeriod)
  return list.find(p => month >= p.startMonth && month <= p.endMonth) ?? list[0]
}

function parseMarkdown(text: string) {
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/^#{1,3}\s+(.+)$/gm, '<p class="font-bold text-on-surface mt-3 mb-1">$1</p>')
    .replace(/^- (.+)$/gm, '<li class="ml-4 list-disc text-body-md text-on-surface">$1</li>')
    .replace(/\n{2,}/g, '</p><p class="mb-2">')
    .replace(/\n/g, '<br/>')
}

const PLAN_OPTIONS: { value: PlanPeriod; label: string; sublabel: string; icon: string; detail: string }[] = [
  { value: 1,  label: '1 เดือน',  sublabel: 'รายเดือน (12 ช่วง)',         icon: 'calendar_view_day',  detail: 'เลือกและวิเคราะห์ทีละเดือน พร้อม KPI และกลยุทธ์รายเดือน' },
  { value: 2,  label: '2 เดือน',  sublabel: '2 เดือน/ช่วง (6 ช่วง)',      icon: 'calendar_view_week', detail: 'แบ่งเป็นช่วง 2 เดือน เหมาะสำหรับการวางแผนระยะกลาง' },
  { value: 3,  label: '3 เดือน',  sublabel: '3 เดือน/ช่วง (4 ช่วง)',      icon: 'calendar_month',      detail: 'แบ่งเป็นช่วงไตรมาส (3 เดือน) สำหรับวางแผนรายไตรมาส' },
  { value: 6,  label: '6 เดือน', sublabel: '6 เดือน/ช่วง (2 ช่วง)',      icon: 'calendar_view_month', detail: 'แบ่งครึ่งปี (ม.ค.–มิ.ย. / ก.ค.–ธ.ค.) เหมาะสำหรับวางแผนรายครึ่งปี' },
  { value: 12, label: '1 ปี',    sublabel: 'ทั้งปี (1 ช่วง)',             icon: 'calendar_today',      detail: 'วิเคราะห์ภาพรวมทั้งปีและวางแผนกลยุทธ์ระดับปี' },
]

export default function AnalyticsClient({ history, initialYear, initialMonth }: Props) {
  const [year, setYear]             = useState(initialYear)
  const [planPeriod, setPlanPeriod] = useState<PlanPeriod>(3)
  const [showModal, setShowModal]   = useState(false)
  const [loading, setLoading]       = useState(false)
  const [analysis, setAnalysis]     = useState('')
  const [monthly, setMonthly]       = useState<MonthlyData[]>([])
  const [categories, setCategories] = useState<CategoryData[]>([])
  const [growth, setGrowth]         = useState<string | null>(null)
  const [current, setCurrent]       = useState<CurrentSummary | null>(null)
  const hasLoaded                   = useRef(false)

  const initPeriod                         = findPeriod(3, initialMonth)
  const [startMonth, setStartMonth]        = useState(initPeriod.startMonth)
  const [endMonth, setEndMonth]            = useState(initPeriod.endMonth)
  const [pendingPlanPeriod, setPendingPlanPeriod] = useState<PlanPeriod>(3)

  const years   = [...new Set(history.map(h => h.year))].sort((a, b) => b - a)
  const periods = getPeriods(planPeriod)

  async function loadAnalytics(
    opts: { yr?: number; sm?: number; em?: number; period?: PlanPeriod; skipAI?: boolean } = {}
  ) {
    const yr     = opts.yr     ?? year
    const sm     = opts.sm     ?? startMonth
    const em     = opts.em     ?? endMonth
    const period = opts.period ?? planPeriod
    const skipAI = opts.skipAI ?? false

    setLoading(true)
    if (!skipAI) setAnalysis('')
    try {
      const res = await fetch('/api/ai/analytics', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ year: yr, startMonth: sm, endMonth: em, planPeriod: period, skipAI }),
      })
      const data = await res.json()
      if (data.error && !skipAI) { setAnalysis('เกิดข้อผิดพลาด: ' + data.error); return }
      if (!skipAI) setAnalysis(data.analysis ?? '')
      setMonthly(data.monthly ?? [])
      setCategories(data.categories ?? [])
      setGrowth(data.growth ?? null)
      setCurrent(data.current ?? null)
    } catch (e: any) {
      if (!skipAI) setAnalysis('เกิดข้อผิดพลาด: ' + e.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (!hasLoaded.current) { hasLoaded.current = true; loadAnalytics() }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  function handleYearChange(newYear: number) {
    setYear(newYear)
    loadAnalytics({ yr: newYear, skipAI: true })
  }

  function handlePeriodSelect(sm: number, em: number) {
    setStartMonth(sm)
    setEndMonth(em)
    loadAnalytics({ sm, em, skipAI: true })
  }

  function confirmAnalyze() {
    const newPeriods = getPeriods(pendingPlanPeriod)
    const midMonth   = Math.round((startMonth + endMonth) / 2)
    // For planPeriod=12 always use full year; otherwise find matching period
    const matched = pendingPlanPeriod === 12
      ? newPeriods[0]
      : newPeriods.find(p => midMonth >= p.startMonth && midMonth <= p.endMonth) ?? newPeriods[0]
    setPlanPeriod(pendingPlanPeriod)
    setStartMonth(matched.startMonth)
    setEndMonth(matched.endMonth)
    setShowModal(false)
    loadAnalytics({ period: pendingPlanPeriod, sm: matched.startMonth, em: matched.endMonth, skipAI: false })
  }

  const maxRevenue = Math.max(...monthly.map(m => m.revenue), 1)
  const maxCat     = Math.max(...categories.map(c => c.revenue), 1)
  const growthNum  = growth ? parseFloat(growth) : null
  const growthPos  = growthNum !== null && growthNum >= 0

  const selectedPeriodLabel = periods.find(p => p.startMonth === startMonth && p.endMonth === endMonth)?.label ?? ''
  const chosenOption        = PLAN_OPTIONS.find(p => p.value === planPeriod)!

  return (
    <div className="flex flex-col gap-6">

      {/* ── Plan Period Modal ──────────────────────────────────────────────── */}
      {showModal && createPortal(
        <>
          <div
            className="fixed inset-0 bg-black/40 backdrop-blur-sm"
            style={{ zIndex: 9998 }}
            onClick={() => setShowModal(false)}
          />
          <div
            className="fixed bg-surface rounded-3xl shadow-2xl overflow-hidden"
            style={{
              zIndex: 9999,
              top: '50%', left: '50%',
              transform: 'translate(-50%, -50%)',
              width: 'min(calc(100vw - 2rem), 28rem)',
              maxHeight: '90vh',
              display: 'flex', flexDirection: 'column',
            }}
          >
            <div className="px-6 pt-6 pb-4 border-b border-surface-variant">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-primary-container/20 flex items-center justify-center">
                  <span className="material-symbols-outlined text-primary-container text-[22px]">auto_awesome</span>
                </div>
                <div>
                  <h3 className="text-label-lg text-on-surface font-semibold">วิเคราะห์ {selectedPeriodLabel} {year}</h3>
                  <p className="text-body-xs text-on-surface-variant">เลือกรูปแบบการวางแผน</p>
                </div>
                <button
                  onClick={() => setShowModal(false)}
                  className="ml-auto p-1.5 rounded-xl hover:bg-surface-container text-on-surface-variant"
                >
                  <span className="material-symbols-outlined text-[20px]">close</span>
                </button>
              </div>
            </div>

            <div className="px-6 py-5 flex flex-col gap-3 overflow-y-auto">
              <p className="text-body-sm text-on-surface-variant mb-1">ต้องการวางแผนแบ่งเป็นกี่เดือน?</p>
              {PLAN_OPTIONS.map(opt => (
                <button
                  key={opt.value}
                  onClick={() => setPendingPlanPeriod(opt.value)}
                  className={`w-full flex items-start gap-4 px-4 py-4 rounded-2xl border-2 text-left transition-all ${
                    pendingPlanPeriod === opt.value
                      ? 'border-primary-container bg-primary-container/10'
                      : 'border-surface-variant bg-surface-container hover:border-outline-variant'
                  }`}
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 mt-0.5 ${
                    pendingPlanPeriod === opt.value ? 'bg-primary-container text-on-primary' : 'bg-surface-container-high text-on-surface-variant'
                  }`}>
                    <span className="material-symbols-outlined text-[20px]">{opt.icon}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-label-md text-on-surface font-semibold">{opt.label}</span>
                      <span className="text-body-xs text-on-surface-variant">{opt.sublabel}</span>
                    </div>
                    <p className="text-body-xs text-on-surface-variant mt-1 leading-relaxed">{opt.detail}</p>
                  </div>
                  {pendingPlanPeriod === opt.value && (
                    <span className="material-symbols-outlined text-primary-container text-[20px] shrink-0 mt-1">check_circle</span>
                  )}
                </button>
              ))}
            </div>

            <div className="px-6 pb-6 pt-4 flex gap-3 border-t border-surface-variant">
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 py-3 rounded-2xl border border-outline-variant text-on-surface-variant text-label-md hover:bg-surface-container transition-colors"
              >
                ยกเลิก
              </button>
              <button
                onClick={confirmAnalyze}
                disabled={loading}
                className="flex-1 py-3 rounded-2xl bg-primary-container text-on-primary text-label-md font-semibold hover:bg-primary transition-colors flex items-center justify-center gap-2 disabled:opacity-60"
              >
                <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
                วิเคราะห์
              </button>
            </div>
          </div>
        </>,
        document.body
      )}

      {/* ── Selector Row ──────────────────────────────────────────────────── */}
      <div className="flex flex-wrap items-center gap-3">
        {/* Year */}
        <select
          value={year}
          onChange={e => handleYearChange(Number(e.target.value))}
          className="border border-outline-variant rounded-xl px-4 py-2 text-body-md text-on-surface bg-surface"
        >
          {years.map(y => <option key={y} value={y}>{y}</option>)}
        </select>

        {/* Period dropdown */}
        <div className="flex items-center gap-2">
          <span className="material-symbols-outlined text-on-surface-variant text-[18px]">date_range</span>
          <select
            value={`${startMonth}-${endMonth}`}
            onChange={e => {
              const [sm, em] = e.target.value.split('-').map(Number)
              handlePeriodSelect(sm, em)
            }}
            disabled={loading}
            className="border border-outline-variant rounded-xl px-4 py-2 text-body-md text-on-surface bg-surface disabled:opacity-60 min-w-[140px]"
          >
            {periods.map(p => (
              <option key={`${p.startMonth}-${p.endMonth}`} value={`${p.startMonth}-${p.endMonth}`}>
                {p.label}
              </option>
            ))}
          </select>
        </div>

        {/* Period type badge */}
        <span className="text-body-xs text-on-surface-variant bg-surface-container px-3 py-1.5 rounded-full flex items-center gap-1 border border-surface-container-high">
          <span className="material-symbols-outlined text-[14px]">{chosenOption.icon}</span>
          {chosenOption.label}/ช่วง
        </span>

        {/* Analyze button */}
        <button
          onClick={() => { setPendingPlanPeriod(planPeriod); setShowModal(true) }}
          disabled={loading}
          className="flex items-center gap-2 bg-primary-container text-on-primary px-5 py-2 rounded-full text-label-md hover:bg-primary transition-colors disabled:opacity-60 ml-auto"
        >
          <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
          {loading ? 'กำลังวิเคราะห์...' : 'วิเคราะห์ AI'}
        </button>
      </div>

      {/* ── KPI Cards ─────────────────────────────────────────────────────── */}
      {current && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'รายได้รวม',            value: `฿${current.revenue.toLocaleString('th-TH')}`,            icon: 'payments',      color: 'text-primary-container' },
            { label: 'ออเดอร์ทั้งหมด',       value: current.orderCount.toLocaleString(),                      icon: 'receipt_long',  color: 'text-[#f97316]' },
            { label: 'มูลค่าเฉลี่ย/ออเดอร์', value: `฿${Math.round(current.avgOrderValue).toLocaleString()}`, icon: 'shopping_bag',  color: 'text-[#22c55e]' },
            {
              label: 'การเติบโต vs ช่วงก่อน',
              value: growthNum !== null ? `${growthPos ? '+' : ''}${growth}%` : '—',
              icon:  growthPos ? 'trending_up' : 'trending_down',
              color: growthNum === null ? 'text-on-surface-variant' : growthPos ? 'text-green-600' : 'text-error',
            },
          ].map(k => (
            <div key={k.label} className={CARD}>
              <span className={`material-symbols-outlined ${k.color} text-[28px]`}>{k.icon}</span>
              <p className="text-body-sm text-on-surface-variant mt-2">{k.label}</p>
              <p className="text-headline-sm text-on-surface font-bold mt-0.5">{k.value}</p>
            </div>
          ))}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* Monthly Revenue Bar Chart */}
        <div className={CARD}>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-label-lg text-on-surface font-semibold">รายได้รายเดือน</h3>
            {startMonth === endMonth && planPeriod === 12 && (
              <button
                onClick={() => handlePeriodSelect(1, 12)}
                className="text-body-xs text-primary-container flex items-center gap-1 hover:underline"
              >
                <span className="material-symbols-outlined text-[14px]">arrow_back</span>
                ดูทั้งปี
              </button>
            )}
          </div>
          {monthly.length === 0 ? (
            <div className="h-40 flex items-center justify-center text-on-surface-variant text-body-sm">
              {loading ? 'กำลังโหลด...' : 'ไม่มีข้อมูล'}
            </div>
          ) : (
            <div className="flex items-end gap-1.5 h-40">
              {monthly.map(m => {
                const pct        = maxRevenue > 0 ? (m.revenue / maxRevenue) * 100 : 0
                const isSelected = startMonth === m.month && endMonth === m.month
                const hasData    = m.revenue > 0
                return (
                  <div
                    key={m.month}
                    onClick={() => hasData && handlePeriodSelect(m.month, m.month)}
                    className={`flex-1 flex flex-col items-center gap-1 rounded-lg transition-all ${
                      hasData ? 'cursor-pointer group' : 'cursor-default'
                    } ${isSelected ? 'bg-primary-container/10 ring-1 ring-primary-container rounded-lg' : 'hover:bg-surface-container'}`}
                  >
                    <span className="text-[9px] text-on-surface-variant pt-1">{m.orderCount || ''}</span>
                    <div className="w-full bg-surface-container rounded-t-lg relative" style={{ height: '100px' }}>
                      <div
                        className={`w-full rounded-t-lg absolute bottom-0 transition-all duration-500 ${
                          isSelected ? 'bg-[#f97316]' : 'bg-primary-container group-hover:bg-primary-container/80'
                        }`}
                        style={{ height: `${pct}%` }}
                      />
                    </div>
                    <span className={`text-[10px] font-medium ${isSelected ? 'text-[#f97316]' : 'text-on-surface-variant'}`}>
                      {m.monthName}
                    </span>
                    <span className={`text-[9px] font-bold pb-1 ${isSelected ? 'text-[#f97316]' : 'text-primary-container'}`}>
                      {m.revenue > 0 ? `฿${(m.revenue / 1000).toFixed(0)}K` : '—'}
                    </span>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* Category Breakdown */}
        <div className={CARD}>
          <h3 className="text-label-lg text-on-surface font-semibold mb-4">หมวดอาหารที่ทำรายได้สูงสุด</h3>
          {categories.length === 0 ? (
            <div className="h-40 flex items-center justify-center text-on-surface-variant text-body-sm">
              {loading ? 'กำลังโหลด...' : 'ไม่มีข้อมูล'}
            </div>
          ) : (
            <div className="flex flex-col gap-2.5">
              {categories.map((c, i) => (
                <div key={c.category}>
                  <div className="flex justify-between text-body-sm text-on-surface mb-1">
                    <span className="flex items-center gap-2">
                      <span className={`w-2.5 h-2.5 rounded-full ${BAR_COLORS[i % BAR_COLORS.length]}`} />
                      {c.category}
                    </span>
                    <span className="text-on-surface-variant font-medium">{c.share}%</span>
                  </div>
                  <div className="h-2 bg-surface-container rounded-full overflow-hidden">
                    <div
                      className={`h-full ${BAR_COLORS[i % BAR_COLORS.length]} rounded-full transition-all duration-700`}
                      style={{ width: `${(c.revenue / maxCat) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Quarterly Trend Sparkline */}
      {history.length > 1 && (
        <div className={CARD}>
          <h3 className="text-label-lg text-on-surface font-semibold mb-4">แนวโน้มรายได้ย้อนหลัง</h3>
          <div className="flex items-end gap-2 h-24 overflow-x-auto">
            {[...history].reverse().map(h => {
              const maxH    = Math.max(...history.map(x => x.revenue), 1)
              const pct     = (h.revenue / maxH) * 100
              const qStart  = (h.quarter - 1) * 3 + 1
              const qEnd    = h.quarter * 3
              const isCur   = h.year === year && qStart <= endMonth && qEnd >= startMonth
              return (
                <div key={`${h.year}Q${h.quarter}`} className="flex-1 min-w-12 flex flex-col items-center gap-1">
                  <div className="w-full bg-surface-container rounded-t relative" style={{ height: '64px' }}>
                    <div
                      className={`w-full rounded-t absolute bottom-0 transition-all duration-500 ${isCur ? 'bg-primary-container' : 'bg-surface-container-highest'}`}
                      style={{ height: `${pct}%` }}
                    />
                  </div>
                  <span className={`text-[10px] font-medium ${isCur ? 'text-primary-container' : 'text-on-surface-variant'}`}>
                    Q{h.quarter}/{h.year}
                  </span>
                </div>
              )
            })}
          </div>
        </div>
      )}

      {/* AI Analysis */}
      <div className={`${CARD} border-primary-container/30`}>
        <div className="flex items-center gap-2 mb-4">
          <span className="material-symbols-outlined text-primary-container text-[24px]">auto_awesome</span>
          <h3 className="text-label-lg text-on-surface font-semibold">AI Prescriptive Analysis</h3>
          <span className="ml-auto text-body-xs text-on-surface-variant bg-surface-container px-2 py-0.5 rounded-full flex items-center gap-1">
            <span className="material-symbols-outlined text-[12px]">{chosenOption.icon}</span>
            {selectedPeriodLabel} {year} · {chosenOption.label}
          </span>
        </div>

        {loading ? (
          <div className="flex items-center gap-3 py-8 justify-center">
            <span className="material-symbols-outlined animate-spin text-primary-container">progress_activity</span>
            <span className="text-body-md text-on-surface-variant">AI กำลังวิเคราะห์ข้อมูล...</span>
          </div>
        ) : analysis ? (
          <div
            className="text-body-md text-on-surface leading-relaxed prose-sm"
            dangerouslySetInnerHTML={{ __html: parseMarkdown(analysis) }}
          />
        ) : (
          <div className="flex flex-col items-center gap-3 py-8 text-on-surface-variant">
            <span className="material-symbols-outlined text-[48px] opacity-30">insights</span>
            <p className="text-body-md">กด &quot;วิเคราะห์ AI&quot; เพื่อรับคำแนะนำเชิงกลยุทธ์</p>
          </div>
        )}
      </div>

    </div>
  )
}
