'use client'

// ─── Brand colors ─────────────────────────────────────────────────────────────
const ORANGE  = 'FF6B35'
const DARK    = '1C1917'
const GRAY    = '6B7280'
const LIGHT   = 'FFF7F4'
const WHITE   = 'FFFFFF'
const GREEN   = '22C55E'
const BLUE    = '3B82F6'

type Row = Record<string, unknown>

interface ExportData {
  rows: Row[]
  label: string
  filename: string
  dateRange: { from: string; to: string } | null
  generatedAt: string
}

function fmt(v: unknown): string {
  if (v === null || v === undefined) return '—'
  return String(v)
}

function num(v: unknown): number {
  return typeof v === 'number' ? v : parseFloat(String(v ?? '0')) || 0
}

// ─── Aggregate helpers ────────────────────────────────────────────────────────

function countBy(rows: Row[], key: string): { name: string; value: number }[] {
  const map: Record<string, number> = {}
  for (const r of rows) {
    const k = fmt(r[key]) || 'Unknown'
    map[k] = (map[k] ?? 0) + 1
  }
  return Object.entries(map)
    .map(([name, value]) => ({ name, value }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 8)
}

function sumBy(rows: Row[], groupKey: string, sumKey: string): { name: string; value: number }[] {
  const map: Record<string, number> = {}
  for (const r of rows) {
    const k = fmt(r[groupKey]) || 'Unknown'
    map[k] = (map[k] ?? 0) + num(r[sumKey])
  }
  return Object.entries(map)
    .map(([name, value]) => ({ name, value: Math.round(value) }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 8)
}

// ─── Main generator ───────────────────────────────────────────────────────────

export async function generatePptx(data: ExportData, reportKey: string): Promise<void> {
  const PptxGenJS = (await import('pptxgenjs')).default
  const pptx = new PptxGenJS()

  pptx.layout = 'LAYOUT_WIDE'  // 13.33 × 7.5 inches

  const dateLabel = data.dateRange
    ? `${data.dateRange.from.split(' ')[0]}  →  ${data.dateRange.to.split(' ')[0]}`
    : 'All records'

  // ── Slide 1: Cover ──────────────────────────────────────────────────────────
  const cover = pptx.addSlide()
  cover.background = { color: ORANGE }

  cover.addShape(pptx.ShapeType.rect, {
    x: 0, y: 5.5, w: 13.33, h: 2,
    fill: { color: '00000020' },
    line: { type: 'none' },
  })

  cover.addText('Zest & Savory', {
    x: 0.8, y: 1.2, w: 11, h: 0.7,
    fontSize: 20, bold: true, color: WHITE, fontFace: 'Segoe UI',
    transparency: 20,
  })

  cover.addText(data.label, {
    x: 0.8, y: 2.0, w: 11, h: 1.4,
    fontSize: 44, bold: true, color: WHITE, fontFace: 'Segoe UI',
  })

  cover.addText(dateLabel, {
    x: 0.8, y: 3.5, w: 8, h: 0.5,
    fontSize: 18, color: WHITE, fontFace: 'Segoe UI', transparency: 25,
  })

  cover.addText(`${data.rows.length.toLocaleString()} records  •  Generated ${new Date(data.generatedAt).toLocaleDateString('th-TH')}`, {
    x: 0.8, y: 6.2, w: 11, h: 0.4,
    fontSize: 13, color: WHITE, fontFace: 'Segoe UI', transparency: 35,
  })

  // ── Slide 2: KPI Summary ────────────────────────────────────────────────────
  const kpiSlide = pptx.addSlide()
  kpiSlide.background = { color: LIGHT }

  kpiSlide.addText(data.label + ' — Summary', {
    x: 0.5, y: 0.3, w: 12, h: 0.55,
    fontSize: 22, bold: true, color: DARK, fontFace: 'Segoe UI',
  })

  kpiSlide.addText(dateLabel, {
    x: 0.5, y: 0.85, w: 10, h: 0.35,
    fontSize: 13, color: GRAY, fontFace: 'Segoe UI',
  })

  const kpis = buildKPIs(data.rows, reportKey)
  const cardW = 2.8
  const cardH = 1.5

  kpis.forEach((kpi, i) => {
    const x = 0.5 + i * (cardW + 0.2)
    const y = 1.6

    kpiSlide.addShape(pptx.ShapeType.roundRect, {
      x, y, w: cardW, h: cardH,
      fill: { color: WHITE },
      line: { color: 'E5E7EB', width: 1 },
      rectRadius: 0.12,
    })

    kpiSlide.addText(kpi.label, {
      x: x + 0.18, y: y + 0.18, w: cardW - 0.36, h: 0.3,
      fontSize: 11, color: GRAY, fontFace: 'Segoe UI',
    })

    kpiSlide.addText(kpi.value, {
      x: x + 0.18, y: y + 0.52, w: cardW - 0.36, h: 0.65,
      fontSize: 26, bold: true, color: ORANGE, fontFace: 'Segoe UI',
    })

    if (kpi.sub) {
      kpiSlide.addText(kpi.sub, {
        x: x + 0.18, y: y + 1.18, w: cardW - 0.36, h: 0.25,
        fontSize: 10, color: GRAY, fontFace: 'Segoe UI',
      })
    }
  })

  // ── Slides 3+: Charts ───────────────────────────────────────────────────────
  const chartSlides = buildChartSlides(data.rows, reportKey, pptx, dateLabel)
  chartSlides.forEach(fn => fn())

  // ── Last Slide: Data Table (first 25 rows) ───────────────────────────────────
  const tableSlide = pptx.addSlide()
  tableSlide.background = { color: WHITE }

  tableSlide.addText('Data Preview (first 25 rows)', {
    x: 0.4, y: 0.2, w: 12, h: 0.45,
    fontSize: 18, bold: true, color: DARK, fontFace: 'Segoe UI',
  })

  const headers = data.rows.length > 0 ? Object.keys(data.rows[0]) : []
  const previewRows = data.rows.slice(0, 25)

  if (headers.length > 0) {
    const colW = Math.min(1.8, 12.2 / headers.length)
    const tableData = [
      // Header row
      headers.map(h => ({
        text: h,
        options: { bold: true, color: WHITE, fill: { color: ORANGE }, fontSize: 9, fontFace: 'Segoe UI' },
      })),
      // Data rows
      ...previewRows.map((row, ri) =>
        headers.map(h => ({
          text: fmt(row[h]),
          options: {
            fontSize: 8,
            fontFace: 'Segoe UI',
            color: DARK,
            fill: { color: ri % 2 === 0 ? 'FFFFFF' : 'FFF7F4' },
          },
        }))
      ),
    ]

    tableSlide.addTable(tableData, {
      x: 0.4, y: 0.85,
      w: Math.min(12.4, headers.length * colW),
      colW: Array(headers.length).fill(colW),
      rowH: 0.22,
      border: { type: 'solid', color: 'E5E7EB', pt: 0.5 },
    })
  }

  // ── Canva tip slide ──────────────────────────────────────────────────────────
  const tipSlide = pptx.addSlide()
  tipSlide.background = { color: '7C3AED' }

  tipSlide.addText('💡 นำเข้าใน Canva', {
    x: 1, y: 1.8, w: 11, h: 0.8,
    fontSize: 36, bold: true, color: WHITE, fontFace: 'Segoe UI',
  })

  tipSlide.addText(
    'เปิด Canva → สร้างการออกแบบใหม่ → อัพโหลด → เลือกไฟล์ .pptx นี้\nCanva จะแปลงสไลด์ทั้งหมดให้แก้ไขได้ทันที',
    {
      x: 1, y: 2.75, w: 11, h: 1,
      fontSize: 18, color: WHITE, fontFace: 'Segoe UI', transparency: 15,
    }
  )

  tipSlide.addText('canva.com  →  Create a design  →  Import file', {
    x: 1, y: 4.2, w: 11, h: 0.45,
    fontSize: 14, color: WHITE, fontFace: 'Segoe UI',
    transparency: 30,
    italic: true,
  })

  await pptx.writeFile({ fileName: data.filename + '.pptx' })
}

// ─── KPI builder per report type ─────────────────────────────────────────────

function buildKPIs(rows: Row[], reportKey: string): { label: string; value: string; sub?: string }[] {
  if (reportKey === 'orders') {
    const total    = rows.length
    const completed = rows.filter(r => fmt(r['Status']).toLowerCase() === 'completed').length
    const revenue  = rows.reduce((s, r) => s + num(r['Total (฿)']), 0)
    const avg      = total > 0 ? revenue / total : 0
    return [
      { label: 'Total Orders',    value: total.toLocaleString() },
      { label: 'Completed',       value: completed.toLocaleString(), sub: `${Math.round(completed / Math.max(total, 1) * 100)}% completion rate` },
      { label: 'Total Revenue',   value: `฿${Math.round(revenue).toLocaleString()}` },
      { label: 'Avg Order Value', value: `฿${Math.round(avg).toLocaleString()}` },
    ]
  }
  if (reportKey === 'financials') {
    const revenue    = rows.reduce((s, r) => s + num(r['Revenue (฿)']), 0)
    const commission = rows.reduce((s, r) => s + num(r['Commission (฿)']), 0)
    const payout     = rows.reduce((s, r) => s + num(r['Net Payout (฿)']), 0)
    const fee        = rows.reduce((s, r) => s + num(r['Service Fee (฿)']), 0)
    return [
      { label: 'Total Revenue',    value: `฿${Math.round(revenue).toLocaleString()}` },
      { label: 'Platform Commission', value: `฿${Math.round(commission).toLocaleString()}`, sub: '15% of revenue' },
      { label: 'Merchant Payouts', value: `฿${Math.round(payout).toLocaleString()}` },
      { label: 'Service Fees',     value: `฿${Math.round(fee).toLocaleString()}` },
    ]
  }
  if (reportKey === 'restaurants') {
    const total  = rows.length
    const active = rows.filter(r => fmt(r['Status']).toLowerCase() === 'active').length
    const avgRating = rows.reduce((s, r) => s + num(r['Rating']), 0) / Math.max(total, 1)
    const topOrders = rows.reduce((s, r) => s + num(r['Total Orders']), 0)
    return [
      { label: 'Total Restaurants', value: total.toLocaleString() },
      { label: 'Active',            value: active.toLocaleString(), sub: `${Math.round(active / Math.max(total, 1) * 100)}% active` },
      { label: 'Avg Rating',        value: avgRating.toFixed(1) + ' ★' },
      { label: 'Total Orders',      value: topOrders.toLocaleString() },
    ]
  }
  if (reportKey === 'fleet') {
    const total   = rows.length
    const active  = rows.filter(r => ['available', 'busy'].includes(fmt(r['Status']).toLowerCase())).length
    const verified = rows.filter(r => fmt(r['Verified']) === 'Yes').length
    const runs    = rows.reduce((s, r) => s + num(r['Runs Completed']), 0)
    return [
      { label: 'Total Riders',   value: total.toLocaleString() },
      { label: 'Active Riders',  value: active.toLocaleString(), sub: `${Math.round(active / Math.max(total, 1) * 100)}% active` },
      { label: 'Verified',       value: verified.toLocaleString() },
      { label: 'Total Deliveries', value: runs.toLocaleString() },
    ]
  }
  return [{ label: 'Records', value: rows.length.toLocaleString() }]
}

// ─── Chart slide builders ─────────────────────────────────────────────────────

function buildChartSlides(
  rows: Row[],
  reportKey: string,
  pptx: InstanceType<typeof import('pptxgenjs').default>,
  dateLabel: string,
): (() => void)[] {
  const fns: (() => void)[] = []

  function addBarChart(title: string, data: { name: string; value: number }[], color = ORANGE) {
    fns.push(() => {
      const slide = pptx.addSlide()
      slide.background = { color: WHITE }

      slide.addText(title, {
        x: 0.5, y: 0.25, w: 12, h: 0.5,
        fontSize: 20, bold: true, color: DARK, fontFace: 'Segoe UI',
      })
      slide.addText(dateLabel, {
        x: 0.5, y: 0.75, w: 10, h: 0.3,
        fontSize: 11, color: GRAY, fontFace: 'Segoe UI',
      })

      slide.addChart(pptx.ChartType.bar, [
        {
          name: title,
          labels: data.map(d => d.name),
          values: data.map(d => d.value),
        },
      ], {
        x: 0.5, y: 1.2, w: 12.3, h: 5.8,
        barDir: 'bar',
        chartColors: [color],
        showValue: true,
        dataLabelColor: DARK,
        dataLabelFontSize: 9,
        catAxisLabelColor: DARK,
        catAxisLabelFontSize: 10,
        valAxisLabelColor: GRAY,
        valAxisLabelFontSize: 9,
        showLegend: false,
        showTitle: false,
        valGridLine: { style: 'solid', color: 'E5E7EB', size: 0.5 },
      })
    })
  }

  function addPieChart(title: string, data: { name: string; value: number }[]) {
    fns.push(() => {
      const slide = pptx.addSlide()
      slide.background = { color: WHITE }

      slide.addText(title, {
        x: 0.5, y: 0.25, w: 12, h: 0.5,
        fontSize: 20, bold: true, color: DARK, fontFace: 'Segoe UI',
      })

      const pieColors = [ORANGE, BLUE, GREEN, '8B5CF6', 'EC4899', 'F59E0B', '06B6D4', '64748B']

      slide.addChart(pptx.ChartType.pie, [
        {
          name: title,
          labels: data.map(d => d.name),
          values: data.map(d => d.value),
        },
      ], {
        x: 0.8, y: 1.1, w: 7.5, h: 5.8,
        chartColors: pieColors,
        showLabel: true,
        showValue: false,
        showPercent: true,
        dataLabelFontSize: 11,
        showLegend: true,
        legendPos: 'r',
        legendFontSize: 11,
        legendColor: DARK,
        showTitle: false,
      })
    })
  }

  if (reportKey === 'orders') {
    addPieChart('Order Status Breakdown', countBy(rows, 'Status'))
    addBarChart('Top Restaurants by Orders', countBy(rows, 'Restaurant'))
    const revenueByRest = sumBy(rows, 'Restaurant', 'Total (฿)')
    addBarChart('Top Restaurants by Revenue (฿)', revenueByRest, BLUE)
  }

  if (reportKey === 'financials') {
    const revByDate = sumBy(rows, 'Date', 'Revenue (฿)')
    addBarChart('Daily Revenue (฿)', revByDate.slice(0, 14), ORANGE)
    const commByRest = sumBy(rows, 'Restaurant', 'Commission (฿)')
    addBarChart('Commission by Restaurant (฿)', commByRest, BLUE)
  }

  if (reportKey === 'restaurants') {
    addPieChart('Restaurants by Category', countBy(rows, 'Category'))
    addBarChart('Top Restaurants by Total Orders', sumBy(rows, 'Name', 'Total Orders'))
  }

  if (reportKey === 'fleet') {
    addPieChart('Riders by Status', countBy(rows, 'Status'))
    addPieChart('Riders by Vehicle Type', countBy(rows, 'Type'))
    addBarChart('Top Riders by Deliveries Completed', sumBy(rows, 'Name', 'Runs Completed'), GREEN)
  }

  return fns
}
