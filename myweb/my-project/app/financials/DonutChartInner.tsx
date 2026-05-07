'use client'

import { useEffect, useRef } from 'react'
import type { RevenueBreakdown } from './FinancialDonutChart'

export default function DonutChartInner({ data }: { data: RevenueBreakdown }) {
    const canvasRef = useRef<HTMLCanvasElement>(null)
    const chartRef  = useRef<any>(null)

    useEffect(() => {
        let mounted = true
        ;(async () => {
            const { Chart, registerables } = await import('chart.js')
            Chart.register(...registerables)
            if (!canvasRef.current || !mounted) return

            chartRef.current?.destroy()

            const total = data.merchantPayouts + data.platformCommission + data.serviceFees
            const pct = (v: number) => total > 0 ? Math.round((v / total) * 100) : 0

            chartRef.current = new Chart(canvasRef.current, {
                type: 'doughnut',
                data: {
                    labels: ['Merchant Payouts', 'Platform Commission', 'Service Fees'],
                    datasets: [{
                        data: [data.merchantPayouts, data.platformCommission, data.serviceFees],
                        backgroundColor: ['#e9e1dc', '#ff6b35', '#00a7cb'],
                        borderWidth: 0,
                        hoverOffset: 4,
                    }],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '75%',
                    plugins: {
                        legend: {
                            position: 'bottom',
                            labels: { usePointStyle: true, padding: 16, color: '#1e1b18', font: { size: 12 } },
                        },
                        tooltip: {
                            backgroundColor: '#1e1b18',
                            padding: 12,
                            cornerRadius: 8,
                            callbacks: {
                                label: ctx => {
                                    const v = Number(ctx.parsed)
                                    return ` ${ctx.label}: $${v.toLocaleString()} (${pct(v)}%)`
                                },
                            },
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
