'use client'

import dynamic from 'next/dynamic'

const DonutChart = dynamic(() => import('./DonutChartInner'), { ssr: false })

export type RevenueBreakdown = {
    merchantPayouts:    number
    platformCommission: number
    serviceFees:        number
}

export default function FinancialDonutChart({ data }: { data: RevenueBreakdown }) {
    return <DonutChart data={data} />
}
