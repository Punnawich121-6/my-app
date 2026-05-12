"use client"
import dynamic from "next/dynamic"

const RevenueChart = dynamic(() => import("./RevenueChart"), { ssr: false })

type DailyRevenue = {
  date: string
  revenue: number
  orderCount: number
}

export default function RevenueChartWrapper({ data }: { data: DailyRevenue[] }) {
  return <RevenueChart data={data} />
}
