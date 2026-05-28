import { getRiderWalletStats, getRiderWalletSummary, getAllRidersForWallet, getPendingLoanRequests } from '@/app/lib/riderWallet'
import RiderWalletClient from './RiderWalletClient'
import RiderLoanApprovals from './RiderLoanApprovals'

export default async function RiderWalletSection() {
  const [stats, rows, allRiders, pendingLoans] = await Promise.all([
    getRiderWalletStats(),
    getRiderWalletSummary(),
    getAllRidersForWallet(),
    getPendingLoanRequests(),
  ])

  return (
    <section className="mt-10">
      {/* Section header */}
      <div className="flex justify-between items-center mb-5 flex-wrap gap-3">
        <div>
          <h3 className="text-headline-md text-on-surface flex items-center gap-2">
            <span className="material-symbols-outlined text-primary">account_balance_wallet</span>
            Pre-Paid · ออกเงินล่วงหน้าให้ไรเดอร์
          </h3>
          <p className="text-body-sm text-on-surface-variant mt-1">
            บันทึกการที่บริษัทออกเงินแทนไรเดอร์ก่อน แล้วหักคืนเมื่อไรเดอร์เติมวอลเล็ต
          </p>
        </div>
      </div>

      {/* Pending Loan Requests */}
      <RiderLoanApprovals loans={pendingLoans} />

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-variant shadow-sm relative overflow-hidden">
          <div className="absolute -right-4 -top-4 w-20 h-20 bg-orange-500/5 rounded-full blur-xl" />
          <div className="flex items-center gap-2 mb-3 relative z-10">
            <div className="p-2 bg-orange-50 rounded-lg">
              <span className="material-symbols-outlined text-orange-500 text-[20px]">money_off</span>
            </div>
            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">ยอดที่บริษัทออกค้างอยู่</span>
          </div>
          <p className="text-headline-lg text-orange-500 font-semibold relative z-10">
            ฿{stats.total_debt.toLocaleString('th-TH', { minimumFractionDigits: 2 })}
          </p>
        </div>

        <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-variant shadow-sm relative overflow-hidden">
          <div className="absolute -right-4 -top-4 w-20 h-20 bg-orange-500/5 rounded-full blur-xl" />
          <div className="flex items-center gap-2 mb-3 relative z-10">
            <div className="p-2 bg-orange-50 rounded-lg">
              <span className="material-symbols-outlined text-orange-500 text-[20px]">person_alert</span>
            </div>
            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">ไรเดอร์ที่ติดหนี้</span>
          </div>
          <p className="text-headline-lg text-on-surface relative z-10">
            {stats.riders_in_debt.toLocaleString()} คน
          </p>
        </div>

        <div className="bg-surface-container-lowest p-5 rounded-xl border border-surface-variant shadow-sm relative overflow-hidden">
          <div className="absolute -right-4 -top-4 w-20 h-20 bg-orange-500/5 rounded-full blur-xl" />
          <div className="flex items-center gap-2 mb-3 relative z-10">
            <div className="p-2 bg-orange-50 rounded-lg">
              <span className="material-symbols-outlined text-orange-500 text-[20px]">payments</span>
            </div>
            <span className="text-label-md text-on-surface-variant uppercase tracking-wider">บริษัทออกเงินไปทั้งหมด</span>
          </div>
          <p className="text-headline-lg text-on-surface relative z-10">
            ฿{stats.total_advanced.toLocaleString('th-TH', { minimumFractionDigits: 2 })}
          </p>
        </div>
      </div>

      {/* Table (client) */}
      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-surface-container">
        <div className="px-6 py-4 border-b border-surface-container bg-surface-bright rounded-t-xl">
          <h4 className="text-title-md text-on-surface">รายการไรเดอร์ที่มีประวัติวอลเล็ต</h4>
        </div>
        <div className="p-4">
          <RiderWalletClient rows={rows} allRiders={allRiders} />
        </div>
      </div>
    </section>
  )
}
