"use client"
import { useEffect, useRef } from "react"

type DailyRevenue = {
  date: string
  revenue: number
  orderCount: number
}

export default function RevenueChart({ data }: { data: DailyRevenue[] }) {
  const canvasRef = useRef<HTMLCanvasElement>(null)
  const chartRef = useRef<any>(null)

  useEffect(() => {
    let mounted = true

    ;(async () => {
      const { Chart, registerables } = await import("chart.js")
      Chart.register(...registerables)
      if (!canvasRef.current || !mounted) return

      chartRef.current?.destroy()

      const labels = data.map(d => {
        // T12:00:00 ป้องกัน timezone shift ทำให้วันคลาดเคลื่อน
        const date = new Date(d.date + "T12:00:00")
        return date.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" })
      })
      const revenues = data.map(d => Number(d.revenue))
      const orderCounts = data.map(d => Number(d.orderCount))

      const ctx = canvasRef.current.getContext("2d")!
      const gradient = ctx.createLinearGradient(0, 0, 0, 220)
      gradient.addColorStop(0, "rgba(234, 88, 12, 0.18)")
      gradient.addColorStop(1, "rgba(234, 88, 12, 0.01)")

      chartRef.current = new Chart(canvasRef.current, {
        type: "bar",
        data: {
          labels,
          datasets: [
            {
              label: "Revenue",
              data: revenues,
              backgroundColor: gradient,
              borderColor: "rgb(234, 88, 12)",
              borderWidth: 2,
              borderRadius: 8,
              hoverBackgroundColor: "rgba(234, 88, 12, 0.28)",
              yAxisID: "y",
            },
            {
              label: "Orders",
              data: orderCounts,
              type: "line" as const,
              borderColor: "rgba(99, 102, 241, 0.7)",
              backgroundColor: "rgba(99, 102, 241, 0.08)",
              borderWidth: 2,
              pointBackgroundColor: "rgb(99, 102, 241)",
              pointRadius: 4,
              tension: 0.4,
              fill: false,
              yAxisID: "y2",
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: {
            legend: {
              display: true,
              position: "top",
              align: "end",
              labels: {
                font: { size: 11 },
                color: "#9ca3af",
                usePointStyle: true,
                pointStyleWidth: 8,
                boxHeight: 6,
              },
            },
            tooltip: {
              backgroundColor: "rgba(255,255,255,0.97)",
              titleColor: "#111827",
              bodyColor: "#6b7280",
              borderColor: "rgba(0,0,0,0.08)",
              borderWidth: 1,
              padding: 10,
              callbacks: {
                label: ctx => {
                  if (ctx.dataset.label === "Revenue") {
                    const v = ctx.parsed.y ?? 0
                    return `  Revenue: $${v >= 1000 ? (v / 1000).toFixed(1) + "k" : v.toFixed(0)}`
                  }
                  return `  Orders: ${ctx.parsed.y ?? 0}`
                },
              },
            },
          },
          scales: {
            x: {
              grid: { display: false },
              ticks: { font: { size: 11 }, color: "#9ca3af" },
              border: { display: false },
            },
            y: {
              position: "left",
              grid: { color: "rgba(0,0,0,0.04)" },
              ticks: {
                font: { size: 11 },
                color: "#9ca3af",
                callback: v => `$${Number(v) >= 1000 ? (Number(v) / 1000).toFixed(0) + "k" : v}`,
              },
              border: { display: false },
            },
            y2: {
              position: "right",
              grid: { display: false },
              ticks: { font: { size: 11 }, color: "#a5b4fc" },
              border: { display: false },
            },
          },
        },
      })
    })()

    return () => {
      mounted = false
      chartRef.current?.destroy()
      chartRef.current = null
    }
  }, [data])

  return <canvas ref={canvasRef} />
}
