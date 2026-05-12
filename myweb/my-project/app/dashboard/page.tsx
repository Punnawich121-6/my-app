import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Navbar from "../component/navbar"
import RevenueChartWrapper from "../component/RevenueChartWrapper"
import AutoRefresh from "../component/AutoRefresh"
import {
  getDashboardStats,
  getLiveOrders,
  getTopPerformers,
  getDailyRevenue,
  getOrderStatusBreakdown,
} from "@/app/lib/dashboard"

// ฟังก์ชันสำหรับฟอร์แมตตัวเลขเป็นรูปแบบเงิน เช่น 1500 -> $1.5k, 500 -> $500
function formatCurrency(amount: number): string {
  if (amount >= 1000) return `$${(amount / 1000).toFixed(1)}k`
  return `$${amount.toFixed(0)}`
}
// ฟังก์ชันสำหรับฟอร์แมตเวลาให้อยู่ในรูปแบบที่อ่านง่าย เช่น 14:30 PM
function formatTime(date: Date): string {
  return new Intl.DateTimeFormat("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(new Date(date))
}

// ฟังก์ชันสำหรับกำหนดสไตล์ของ badge ตามสถานะของ Order
function getStatusStyle(status: string): string {
  switch (status) {
    case "PREPARING":        return "bg-tertiary-fixed text-on-tertiary-fixed"
    case "OUT_FOR_DELIVERY": return "bg-secondary-container text-on-secondary-container"
    case "DELIVERED":        return "bg-green-100 text-green-800"
    case "DELAYED":          return "bg-error-container text-on-error-container"
    case "CANCELLED":        return "bg-gray-100 text-gray-800"
    default:                 return "bg-surface-variant text-on-surface-variant"
  }
}

// ฟังก์ชันสำหรับกำหนด label ของแต่ละ status
const STATUS_LABEL: Record<string, string> = {
  PENDING:          "Pending",
  CONFIRMED:        "Confirmed",
  PREPARING:        "Preparing",
  OUT_FOR_DELIVERY: "Out for Delivery",
  DELIVERED:        "Delivered",
  DELAYED:          "Delayed",
  CANCELLED:        "Cancelled",
  REFUNDED:         "Refunded",
}

// สี progress bar และ dot แต่ละ status สำหรับ Order Breakdown
const STATUS_BAR: Record<string, { bar: string; dot: string }> = {
  PENDING:          { bar: "bg-amber-400",  dot: "bg-amber-400"  },
  CONFIRMED:        { bar: "bg-blue-400",   dot: "bg-blue-400"   },
  PREPARING:        { bar: "bg-orange-500", dot: "bg-orange-500" },
  OUT_FOR_DELIVERY: { bar: "bg-sky-500",    dot: "bg-sky-500"    },
  DELIVERED:        { bar: "bg-green-500",  dot: "bg-green-500"  },
  DELAYED:          { bar: "bg-red-400",    dot: "bg-red-400"    },
  CANCELLED:        { bar: "bg-gray-400",   dot: "bg-gray-400"   },
  REFUNDED:         { bar: "bg-purple-400", dot: "bg-purple-400" },
}

// เก็บผลลัพธ์ของการ query ที่ได้จากฟังก์ชัน getLiveOrders() ซึ่งเป็นอาเรย์ของคำสั่งซื้อที่กำลังดำเนินการอยู่ 5 รายการล่าสุด
export default async function Dashboard() {
  const session = await verifySession()
  if (!session) redirect('/login')

  const [stats, liveOrders, topPerformers, dailyRevenue, statusBreakdown] = await Promise.all([
    getDashboardStats(),
    getLiveOrders(),
    getTopPerformers(),
    getDailyRevenue(),
    getOrderStatusBreakdown(),
  ])

  // สร้างตัวแปร today เพื่อแสดงวันที่ปัจจุบันในรูปแบบที่อ่านง่าย เช่น "Monday, Jan 1"
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "short",
    day: "numeric",
  })

  //  หาผลรวมของออเดอร์ทั้งหมดในวันนี้ โดยการใช้ reduce กับอาเรย์ statusBreakdown ซึ่งเก็บข้อมูลจำนวนคำสั่งซื้อในแต่ละสถานะ และแปลงค่า count เป็นตัวเลขด้วย Number() ก่อนนำมาบวกกันเพื่อหาผลรวมทั้งหมด
  const totalOrdersToday = statusBreakdown.reduce((s, r) => s + Number(r.count), 0)

  return (
    <>
      <AutoRefresh interval={10_000} /> // reflesh ข้อมูลทุกๆ 10 วินาที (10,000 มิลลิวินาที)
      <Navbar /> // แสดง Navbar ที่นำเข้ามาจาก component/navbar.tsx

      // md: ml-64 = Margin Left ขนาด 64unit = 256px  spacing for sidebar 
      <main className="md:ml-64 pt-20 px-4 md:px-8 pb-12 min-h-screen"> 

        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
          <div>
            <h2 className="text-headline-lg text-on-surface mb-1">Good morning, Admin</h2>
            <p className="text-body-md text-on-surface-variant">
              Here&apos;s what&apos;s happening with Zest &amp; Savory today.
            </p>
          </div>
          <div className="flex items-center gap-3 bg-surface-container px-4 py-2 rounded-full border border-surface-variant self-start sm:self-auto shadow-sm">
            <span className="material-symbols-outlined text-on-surface-variant">calendar_today</span>
            <span className="text-label-md text-on-surface">Today, {today}</span>
          </div>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          {/* Total Revenue */}
          <div className="bg-surface-container-lowest p-6 rounded-2xl shadow-[0_4px_20px_rgba(255,107,53,0.05)] border border-surface-variant/50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(255,107,53,0.1)] transition-shadow">
            <div className="absolute -right-6 -top-6 w-24 h-24 bg-primary-container/10 rounded-full blur-xl group-hover:bg-primary-container/20 transition-colors" />
            <div className="flex justify-between items-start mb-4">
              <div className="w-10 h-10 rounded-full bg-primary-container/10 flex items-center justify-center text-primary-container">
                <span className="material-symbols-outlined">attach_money</span>
              </div>
              <span className={`text-label-sm px-2 py-1 rounded-full flex items-center gap-1 ${
                stats.revenueChangePercent >= 0 ? "text-green-600 bg-green-50" : "text-red-600 bg-red-50"
              }`}>
                <span className="material-symbols-outlined text-[14px]">
                  {stats.revenueChangePercent >= 0 ? "trending_up" : "trending_down"}
                </span>
                {stats.revenueChangePercent >= 0 ? "+" : ""}{stats.revenueChangePercent}%
              </span>
            </div>
            <h3 className="text-label-md text-on-surface-variant mb-1 uppercase tracking-wider">Total Revenue</h3>
            <p className="text-headline-lg text-on-surface">{formatCurrency(stats.totalRevenue)}</p>
            <p className="text-body-xs text-on-surface-variant mt-1">vs yesterday</p>
          </div>

          {/* Active Orders */}
          <div className="bg-surface-container-lowest p-6 rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-shadow">
            <div className="absolute -right-6 -top-6 w-24 h-24 bg-tertiary-container/10 rounded-full blur-xl group-hover:bg-tertiary-container/20 transition-colors" />
            <div className="flex justify-between items-start mb-4">
              <div className="w-10 h-10 rounded-full bg-tertiary-container/10 flex items-center justify-center text-tertiary-container">
                <span className="material-symbols-outlined">receipt_long</span>
              </div>
            </div>
            <h3 className="text-label-md text-on-surface-variant mb-1 uppercase tracking-wider">Active Orders</h3>
            <p className="text-headline-lg text-on-surface">{stats.activeOrders}</p>
            <p className="text-body-xs text-on-surface-variant mt-1">{totalOrdersToday} total today</p>
          </div>

          {/* Active Riders */}
          <div className="bg-surface-container-lowest p-6 rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-shadow">
            <div className="absolute -right-6 -top-6 w-24 h-24 bg-secondary-container/30 rounded-full blur-xl group-hover:bg-secondary-container/50 transition-colors" />
            <div className="flex justify-between items-start mb-4">
              <div className="w-10 h-10 rounded-full bg-secondary-container flex items-center justify-center text-on-secondary-container">
                <span className="material-symbols-outlined">two_wheeler</span>
              </div>
            </div>
            <h3 className="text-label-md text-on-surface-variant mb-1 uppercase tracking-wider">Active Riders</h3>
            <p className="text-headline-lg text-on-surface">{stats.activeRiders}</p>
            <p className="text-body-xs text-on-surface-variant mt-1">online now</p>
          </div>

          {/* Pending Issues */}
          <div className="bg-surface-container-lowest p-6 rounded-2xl shadow-[0_4px_20px_rgba(186,26,26,0.05)] border border-surface-variant/50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(186,26,26,0.1)] transition-shadow">
            <div className="absolute -right-6 -top-6 w-24 h-24 bg-error-container/30 rounded-full blur-xl group-hover:bg-error-container/50 transition-colors" />
            <div className="flex justify-between items-start mb-4">
              <div className="w-10 h-10 rounded-full bg-error-container flex items-center justify-center text-on-error-container">
                <span className="material-symbols-outlined">error</span>
              </div>
            </div>
            <h3 className="text-label-md text-on-surface-variant mb-1 uppercase tracking-wider">Pending Issues</h3>
            <p className="text-headline-lg text-error">{stats.pendingIssues}</p>
            <p className="text-body-xs text-on-surface-variant mt-1">delayed &amp; refunded today</p>
          </div>
        </div>

        {/* Revenue Chart + Order Status Breakdown */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">

          {/* Revenue Chart — 7 days */}
          <div className="lg:col-span-2 bg-surface-container-lowest rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 p-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 gap-2">
              <div>
                <h3 className="text-headline-sm text-on-surface">Revenue Overview</h3>
                <p className="text-body-sm text-on-surface-variant mt-0.5">
                  Last 7 days — excluding cancelled &amp; refunded
                </p>
              </div>
            </div>
            <div className="h-56">
              <RevenueChartWrapper data={dailyRevenue} />
            </div>
          </div>

          {/* Order Status Breakdown */}
          <div className="bg-surface-container-lowest rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 p-6 flex flex-col">
            <div className="flex justify-between items-center mb-1">
              <h3 className="text-headline-sm text-on-surface">Today&apos;s Orders</h3>
              <span className="text-label-sm text-on-surface-variant bg-surface px-2.5 py-0.5 rounded-full border border-surface-variant/50">
                {totalOrdersToday} total
              </span>
            </div>
            <p className="text-body-sm text-on-surface-variant mb-5">Breakdown by status</p>

            {totalOrdersToday === 0 ? (
              <div className="flex-1 flex items-center justify-center text-body-md text-on-surface-variant">
                No orders today yet.
              </div>
            ) : (
              <div className="space-y-4 flex-1">
                {statusBreakdown.map(item => {
                  const pct = Math.round((Number(item.count) / totalOrdersToday) * 100)
                  const style = STATUS_BAR[item.status] ?? { bar: "bg-gray-300", dot: "bg-gray-300" }
                  return (
                    <div key={item.status}>
                      <div className="flex items-center justify-between mb-1.5">
                        <div className="flex items-center gap-2">
                          <span className={`w-2 h-2 rounded-full shrink-0 ${style.dot}`} />
                          <span className="text-label-md text-on-surface">
                            {STATUS_LABEL[item.status] ?? item.status}
                          </span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-label-md text-on-surface font-semibold">{Number(item.count)}</span>
                          <span className="text-body-xs text-on-surface-variant w-8 text-right">{pct}%</span>
                        </div>
                      </div>
                      <div className="h-1.5 w-full bg-surface-variant/40 rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full ${style.bar} transition-all duration-500`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>

        {/* Live Orders Table + Top Performers */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

          {/* Live Orders Table */}
          <div className="lg:col-span-2 bg-surface-container-lowest rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 flex flex-col">
            <div className="p-6 border-b border-surface-variant/50 flex justify-between items-center">
              <div>
                <h3 className="text-headline-sm text-on-surface">Live Order Monitoring</h3>
                <p className="text-body-sm text-on-surface-variant mt-0.5">5 most recent active orders</p>
              </div>
              <button className="text-primary-container text-label-md hover:underline">View All</button>
            </div>
            <div className="overflow-x-auto flex-1">
              {liveOrders.length === 0 ? (
                <div className="p-8 text-center text-on-surface-variant text-body-md">
                  No active orders at the moment.
                </div>
              ) : (
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-surface text-label-sm text-on-surface-variant uppercase tracking-wider">
                      <th className="p-4 font-semibold border-b border-surface-variant/50">Order ID</th>
                      <th className="p-4 font-semibold border-b border-surface-variant/50">Restaurant</th>
                      <th className="p-4 font-semibold border-b border-surface-variant/50">Customer</th>
                      <th className="p-4 font-semibold border-b border-surface-variant/50">Status</th>
                      <th className="p-4 font-semibold border-b border-surface-variant/50">Time</th>
                    </tr>
                  </thead>
                  <tbody className="text-body-sm">
                    {liveOrders.map((order, i) => (
                      <tr
                        key={order.orderNumber}
                        className={`hover:bg-surface-container/30 transition-colors ${
                          i < liveOrders.length - 1 ? "border-b border-surface-variant/30" : ""
                        }`}
                      >
                        <td className="p-4 font-medium text-on-surface">#{order.orderNumber}</td>
                        <td className="p-4 text-on-surface-variant">{order.restaurantName}</td>
                        <td className="p-4 text-on-surface-variant">{order.customerName}</td>
                        <td className="p-4">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusStyle(order.status)}`}>
                            {STATUS_LABEL[order.status] ?? order.status}
                          </span>
                        </td>
                        <td className="p-4 text-on-surface-variant">{formatTime(order.createdAt)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>

          {/* Top Performers */}
          <div className="bg-surface-container-lowest rounded-2xl shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-surface-variant/50 p-6 flex flex-col">
            <div className="flex justify-between items-center mb-6">
              <div>
                <h3 className="text-headline-sm text-on-surface">Top Performers</h3>
                <p className="text-body-sm text-on-surface-variant mt-0.5">By order count today</p>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant">more_vert</span>
            </div>
            <div className="space-y-5 flex-1">
              {topPerformers.length === 0 ? (
                <p className="text-body-md text-on-surface-variant">No data yet.</p>
              ) : (
                topPerformers.map((r, i) => (
                  <div key={r.id} className="flex items-center gap-4">
                    <span className="text-label-sm text-on-surface-variant w-4 shrink-0 text-center">
                      {i + 1}
                    </span>
                    <div className="w-11 h-11 rounded-xl overflow-hidden bg-surface-container shrink-0">
                      {r.imageUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img alt={r.name} className="w-full h-full object-cover" src={r.imageUrl} />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-on-surface-variant text-label-sm font-bold">
                          {r.name.charAt(0)}
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="text-label-lg text-on-surface truncate">{r.name}</h4>
                      <p className="text-body-sm text-on-surface-variant">{Number(r.orderCount)} orders</p>
                    </div>
                    <div className="text-right">
                      <p className="text-label-lg text-primary-container">{formatCurrency(Number(r.revenue))}</p>
                    </div>
                  </div>
                ))
              )}
            </div>
            <button className="w-full mt-6 py-2 bg-surface text-primary-container text-label-md rounded-full border border-outline-variant hover:bg-surface-container-high transition-colors">
              View Full Rankings
            </button>
          </div>
        </div>

      </main>
    </>
  )
}
