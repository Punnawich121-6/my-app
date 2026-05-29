import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Link from 'next/link'
import Navbar from '../component/navbar'
import AutoRefresh from '../component/AutoRefresh'
import { getRiderStats, getAllRiders, getPendingRiders } from '@/app/lib/fleet'
import AddRiderModal from '../riders/AddRiderModal'
import EditRiderModal from '../riders/EditRiderModal'
import RiderFilters from '../riders/RiderFilters'
import PendingRiderApprovals from './PendingRiderApprovals'
import RiderLiveMap from './RiderLiveMapClient'
import RiderWalletSection from './RiderWalletSection'

const VEHICLE_ICON: Record<string, string> = {
  motorcycle:    'two_wheeler',
  car:           'directions_car',
  bicycle:       'pedal_bike',
  electric_bike: 'electric_bike',
}

const STATUS_STYLE: Record<string, string> = {
  Available: 'bg-green-50 text-green-700 border-green-200',
  Busy:      'bg-blue-50 text-blue-700 border-blue-200',
  Offline:   'bg-surface-container text-on-surface-variant border-outline-variant',
  Pending:   'bg-amber-50 text-amber-700 border-amber-200',
}

const STATUS_DOT: Record<string, string> = {
  Available: 'bg-green-500',
  Busy:      'bg-blue-500',
  Offline:   'bg-on-surface-variant/40',
  Pending:   'bg-amber-500',
}

export default async function Fleet({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; search?: string; page?: string }>
}) {
  const session = await verifySession()
  if (!session) redirect('/login')

  const { status, search, page } = await searchParams
  const currentStatus = status ?? 'ALL'
  const currentSearch = search ?? ''
  const currentPage   = Math.max(1, Number(page ?? 1))

  const [stats, { riders, total, pageSize }, pendingRiders] = await Promise.all([
    getRiderStats(),
    getAllRiders({ status: currentStatus, search: currentSearch, page: currentPage }),
    getPendingRiders(),
  ])

  const totalPages = Math.ceil(total / pageSize)
  const from = total === 0 ? 0 : (currentPage - 1) * pageSize + 1
  const to   = Math.min(currentPage * pageSize, total)

  function buildHref(overrides: Record<string, string>) {
    const p = new URLSearchParams({ status: currentStatus, search: currentSearch, page: String(currentPage), ...overrides })
    return `?${p.toString()}`
  }

  return (
    <>
      <AutoRefresh interval={30_000} />
      <Navbar />

      <main className="md:ml-64 pt-16 px-4 md:px-8 pb-12 min-h-screen">

        {/* Header */}
        <div className="flex justify-between items-center mt-8 mb-6 gap-4 flex-wrap">
          <div>
            <h2 className="text-headline-lg text-on-surface">Fleet Management</h2>
            <p className="text-body-sm text-on-surface-variant mt-1">Monitor and manage your delivery network in real-time.</p>
          </div>
          <div className="flex items-center gap-3">
            <button className="flex items-center gap-2 px-3 sm:px-4 py-2.5 bg-surface-container-highest border border-outline-variant text-on-surface text-label-lg rounded-full hover:bg-surface-container transition-colors shadow-sm">
              <span className="material-symbols-outlined text-sm">download</span>
              <span className="hidden sm:inline">Export Data</span>
            </button>
            <AddRiderModal />
          </div>
        </div>

        {/* Pending Approvals */}
        <PendingRiderApprovals riders={pendingRiders} />

        {/* KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-tertiary-container/10 rounded-full blur-xl group-hover:bg-tertiary-container/20 transition-colors" />
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-tertiary-container/20 rounded-lg text-tertiary">
                <span className="material-symbols-outlined">group</span>
              </div>
              <span className="flex items-center gap-1 text-tertiary text-label-sm bg-tertiary-container/10 px-2 py-1 rounded-full">
                <span className="material-symbols-outlined text-[12px]">trending_up</span>+2.4%
              </span>
            </div>
            <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1 relative z-10">Total Riders</p>
            <h3 className="text-headline-xl text-on-surface relative z-10">{stats.totalRider.toLocaleString()}</h3>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-[#4ade80]/10 rounded-full blur-xl group-hover:bg-[#4ade80]/20 transition-colors" />
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-[#4ade80]/20 rounded-lg text-[#166534]">
                <span className="material-symbols-outlined">two_wheeler</span>
              </div>
              <span className="flex items-center gap-1 text-[#166534] text-label-sm bg-[#4ade80]/10 px-2 py-1 rounded-full">
                <span className="material-symbols-outlined text-[12px]">trending_up</span>+12%
              </span>
            </div>
            <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1 relative z-10">Active Now</p>
            <h3 className="text-headline-xl text-on-surface relative z-10">{stats.activeRider.toLocaleString()}</h3>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-primary-container/10 rounded-full blur-xl group-hover:bg-primary-container/20 transition-colors" />
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-primary-container/20 rounded-lg text-primary">
                <span className="material-symbols-outlined">local_shipping</span>
              </div>
              <span className="text-label-sm text-on-surface-variant relative z-10">Peak Hours</span>
            </div>
            <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1 relative z-10">On Delivery</p>
            <h3 className="text-headline-xl text-on-surface relative z-10">{stats.onDeliveryRider.toLocaleString()}</h3>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-[#fbbf24]/10 rounded-full blur-xl group-hover:bg-[#fbbf24]/20 transition-colors" />
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-[#fef3c7] rounded-lg text-[#b45309]">
                <span className="material-symbols-outlined">pending_actions</span>
              </div>
              <span className="text-label-sm text-[#b45309] bg-[#fef3c7] px-2 py-1 rounded-full relative z-10">Requires Action</span>
            </div>
            <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1 relative z-10">Pending Verification</p>
            <h3 className="text-headline-xl text-on-surface relative z-10">{stats.pendingRider.toLocaleString()}</h3>
          </div>
        </div>

        {/* Live Map */}
        <RiderLiveMap />

        {/* Rider Table */}
        <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-surface-container flex flex-col">

          <Suspense fallback={<div className="p-4 h-18 border-b border-surface-container bg-surface-bright rounded-t-xl" />}>
            <RiderFilters currentStatus={currentStatus} currentSearch={currentSearch} />
          </Suspense>

          {/* Mobile card view */}
          <div className="md:hidden divide-y divide-surface-container">
            {riders.length === 0 ? (
              <div className="py-12 text-center text-on-surface-variant text-body-md">
                ไม่พบข้อมูลไรเดอร์
              </div>
            ) : riders.map(r => {
              const sk = r.status as string
              return (
                <div key={r.id} className="p-4 hover:bg-surface-bright transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface font-bold text-sm shrink-0">
                      {r.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-label-lg text-on-background truncate">{r.name}</p>
                      <p className="text-body-sm text-on-surface-variant">{r.phone || '—'}</p>
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                      <span className={`inline-flex items-center gap-1 text-label-sm px-2 py-0.5 rounded-full border ${STATUS_STYLE[sk] ?? 'bg-surface-variant text-on-surface-variant border-outline-variant'}`}>
                        {sk === 'Pending'
                          ? <span className="material-symbols-outlined text-[11px]">schedule</span>
                          : <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[sk] ?? 'bg-slate-400'}`} />}
                        {r.status}
                      </span>
                      <EditRiderModal rider={{
                        id:            r.id,
                        name:          r.name,
                        email:         r.email,
                        phone:         r.phone,
                        vehicle:       r.vehicle,
                        status:        r.status,
                        rating:        r.rating,
                        runsCompleted: r.runsCompleted,
                        isVerified:    r.isVerified,
                      }} />
                    </div>
                  </div>
                  <div className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1.5 pl-13">
                    <span className="inline-flex items-center gap-1.5 bg-surface-container px-2.5 py-1 rounded-full text-label-sm text-on-surface-variant">
                      <span className="material-symbols-outlined text-[15px]">{VEHICLE_ICON[r.vehicle] ?? 'two_wheeler'}</span>
                      {r.vehicle}
                    </span>
                    {r.isVerified ? (
                      <span className="inline-flex items-center gap-1 text-green-700 text-label-sm">
                        <span className="material-symbols-outlined text-[15px] text-green-600">verified</span>
                        Verified
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-on-surface-variant text-label-sm">
                        <span className="material-symbols-outlined text-[15px]">unpublished</span>
                        Unverified
                      </span>
                    )}
                    {r.rating !== null && Number(r.rating) > 0 ? (
                      <span className="inline-flex items-center gap-1">
                        <span className="material-symbols-outlined text-amber-500 text-[15px]" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                        <span className="text-label-md text-on-surface">{Number(r.rating).toFixed(1)}</span>
                      </span>
                    ) : (
                      <span className="text-label-sm text-on-surface-variant italic">ใหม่</span>
                    )}
                    <span className="text-label-sm text-on-surface-variant">{r.runsCompleted.toLocaleString()} รอบ</span>
                  </div>
                </div>
              )
            })}
          </div>

          {/* Desktop table view */}
          <div className="hidden md:block overflow-x-auto">
            <table className="w-full text-left border-collapse min-w-180">
              <thead>
                <tr className="border-b border-surface-container bg-surface-bright">
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">ไรเดอร์</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">เบอร์โทร</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">ยานพาหนะ</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">สถานะ</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">คะแนน / รอบ</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">Verified</th>
                  <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-container">
                {riders.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-12 text-center text-on-surface-variant text-body-md">
                      ไม่พบข้อมูลไรเดอร์
                    </td>
                  </tr>
                ) : riders.map(r => {
                  const sk = r.status as string
                  return (
                    <tr key={r.id} className="hover:bg-surface-bright transition-colors">
                      <td className="py-4 px-6">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-on-surface font-bold text-sm shrink-0">
                            {r.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()}
                          </div>
                          <span className="text-label-lg text-on-background">{r.name}</span>
                        </div>
                      </td>
                      <td className="py-4 px-6 text-body-md text-on-surface">{r.phone || '—'}</td>
                      <td className="py-4 px-6">
                        <span className="inline-flex items-center gap-1.5 bg-surface-container px-3 py-1 rounded-full text-label-sm text-on-surface-variant">
                          <span className="material-symbols-outlined text-[16px]">{VEHICLE_ICON[r.vehicle] ?? 'two_wheeler'}</span>
                          {r.vehicle}
                        </span>
                      </td>
                      <td className="py-4 px-6">
                        <span className={`inline-flex items-center gap-1 text-label-md px-2.5 py-1 rounded-full border ${STATUS_STYLE[sk] ?? 'bg-surface-variant text-on-surface-variant border-outline-variant'}`}>
                          {sk === 'Pending'
                            ? <span className="material-symbols-outlined text-[12px]">schedule</span>
                            : <span className={`w-1.5 h-1.5 rounded-full ${STATUS_DOT[sk] ?? 'bg-slate-400'}`} />}
                          {r.status}
                        </span>
                      </td>
                      <td className="py-4 px-6">
                        <div className="flex flex-col gap-0.5">
                          {r.rating !== null && Number(r.rating) > 0 ? (
                            <div className="flex items-center gap-1">
                              <span className="material-symbols-outlined text-amber-500 text-[16px]" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                              <span className="text-label-lg text-on-surface">{Number(r.rating).toFixed(1)}</span>
                            </div>
                          ) : (
                            <span className="text-label-sm text-on-surface-variant italic">ใหม่</span>
                          )}
                          <span className="text-label-sm text-on-surface-variant">{r.runsCompleted.toLocaleString()} รอบ</span>
                        </div>
                      </td>
                      <td className="py-4 px-6">
                        {r.isVerified ? (
                          <span className="inline-flex items-center gap-1 text-green-700 text-label-sm">
                            <span className="material-symbols-outlined text-[16px] text-green-600">verified</span>
                            Verified
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-on-surface-variant text-label-sm">
                            <span className="material-symbols-outlined text-[16px]">unpublished</span>
                            Unverified
                          </span>
                        )}
                      </td>
                      <td className="py-4 px-6 text-right">
                        <EditRiderModal rider={{
                          id:            r.id,
                          name:          r.name,
                          email:         r.email,
                          phone:         r.phone,
                          vehicle:       r.vehicle,
                          status:        r.status,
                          rating:        r.rating,
                          runsCompleted: r.runsCompleted,
                          isVerified:    r.isVerified,
                        }} />
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          <div className="p-4 border-t border-surface-container flex items-center justify-between bg-surface-bright rounded-b-xl flex-wrap gap-3">
            <p className="text-body-sm text-on-surface-variant">Showing {from} to {to} of {total.toLocaleString()} entries</p>
            <div className="flex items-center gap-1">
              <Link scroll={false} href={buildHref({ page: String(currentPage - 1) })} aria-disabled={currentPage <= 1}
                className={`p-2 rounded-lg border border-outline-variant text-on-surface-variant hover:bg-surface-container transition-colors ${currentPage <= 1 ? 'pointer-events-none opacity-40' : ''}`}>
                <span className="material-symbols-outlined text-[20px]">chevron_left</span>
              </Link>
              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                let p: number
                if (totalPages <= 5)                    p = i + 1
                else if (currentPage <= 3)              p = i + 1
                else if (currentPage >= totalPages - 2) p = totalPages - 4 + i
                else                                    p = currentPage - 2 + i
                return (
                  <Link key={p} scroll={false} href={buildHref({ page: String(p) })}
                    className={`w-8 h-8 rounded-lg text-label-md flex items-center justify-center transition-colors ${p === currentPage ? 'bg-primary-container text-on-primary' : 'border border-outline-variant text-on-surface hover:bg-surface-container'}`}>
                    {p}
                  </Link>
                )
              })}
              <Link scroll={false} href={buildHref({ page: String(currentPage + 1) })} aria-disabled={currentPage >= totalPages}
                className={`p-2 rounded-lg border border-outline-variant text-on-surface hover:bg-surface-container transition-colors ${currentPage >= totalPages ? 'pointer-events-none opacity-40' : ''}`}>
                <span className="material-symbols-outlined text-[20px]">chevron_right</span>
              </Link>
            </div>
          </div>
        </div>

        {/* Pre-Paid Rider Wallet */}
        <RiderWalletSection />

      </main>
    </>
  )
}
