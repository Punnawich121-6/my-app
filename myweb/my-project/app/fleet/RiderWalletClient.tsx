'use client'

import { useActionState, useEffect, useState, useTransition } from 'react'
import { advanceRiderWallet, topupRiderWallet, fetchRiderTransactions } from '@/app/actions/riderWallet'
import type { RiderWalletRow } from '@/app/lib/riderWallet'

type RiderWalletTransaction = {
  id: string
  rider_id: string
  type: 'advance' | 'topup' | 'deduction'
  amount: number
  description: string | null
  reference_id: string | null
  created_at: string   // ISO string — Date not serializable across Server Action boundary
}

type Rider = { id: string; name: string; phone: string }

const initState = { success: false, error: null }

// ─── Advance Modal ─────────────────────────────────────────────────────────────
function AdvanceModal({
  riders,
  defaultRider,
  onClose,
}: {
  riders: Rider[]
  defaultRider?: Rider
  onClose: () => void
}) {
  const [state, action, pending] = useActionState(advanceRiderWallet, initState)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-surface-container-lowest rounded-2xl shadow-2xl border border-outline-variant" style={{ width: 'min(440px, calc(100vw - 2rem))' }}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-outline-variant">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-orange-500">account_balance_wallet</span>
            <h3 className="text-title-lg text-on-surface">ออกเงินล่วงหน้าให้ไรเดอร์</h3>
          </div>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-surface-container text-on-surface-variant">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <form action={action} className="p-6 flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">ไรเดอร์</label>
            <select
              name="rider_id"
              defaultValue={defaultRider?.id ?? ''}
              required
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="">-- เลือกไรเดอร์ --</option>
              {riders.map(r => (
                <option key={r.id} value={r.id}>{r.name} ({r.phone})</option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">จำนวนเงิน (฿)</label>
            <input
              name="amount"
              type="number"
              min="1"
              step="0.01"
              placeholder="0.00"
              required
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">หมายเหตุ (ไม่บังคับ)</label>
            <input
              name="description"
              type="text"
              placeholder="เช่น ออกเงินค่าส่งออร์เดอร์ #1234"
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {state.error && (
            <p className="text-error text-body-sm bg-error-container/20 px-3 py-2 rounded-lg">{state.error}</p>
          )}
          {state.success && (
            <p className="text-green-700 text-body-sm bg-green-50 px-3 py-2 rounded-lg">
              บันทึกรายการสำเร็จ ยอดคงเหลือ: ฿{state.balance?.toFixed(2)}
            </p>
          )}

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose}
              className="flex-1 py-2.5 rounded-full border border-outline-variant text-on-surface text-label-lg hover:bg-surface-container transition-colors">
              ยกเลิก
            </button>
            <button type="submit" disabled={pending}
              className="flex-1 py-2.5 rounded-full bg-orange-500 text-white text-label-lg hover:bg-orange-600 transition-colors disabled:opacity-60">
              {pending ? 'กำลังบันทึก...' : 'ยืนยันออกเงิน'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Topup Modal ───────────────────────────────────────────────────────────────
function TopupModal({
  riders,
  defaultRider,
  onClose,
}: {
  riders: Rider[]
  defaultRider?: Rider
  onClose: () => void
}) {
  const [state, action, pending] = useActionState(topupRiderWallet, initState)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-surface-container-lowest rounded-2xl shadow-2xl border border-outline-variant" style={{ width: 'min(440px, calc(100vw - 2rem))' }}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-outline-variant">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-orange-500">add_circle</span>
            <h3 className="text-title-lg text-on-surface">บันทึกการเติมเงินไรเดอร์</h3>
          </div>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-surface-container text-on-surface-variant">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <form action={action} className="p-6 flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">ไรเดอร์</label>
            <select
              name="rider_id"
              defaultValue={defaultRider?.id ?? ''}
              required
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            >
              <option value="">-- เลือกไรเดอร์ --</option>
              {riders.map(r => (
                <option key={r.id} value={r.id}>{r.name} ({r.phone})</option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">จำนวนเงินที่เติม (฿)</label>
            <input
              name="amount"
              type="number"
              min="1"
              step="0.01"
              placeholder="0.00"
              required
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-label-md text-on-surface-variant">หมายเหตุ (ไม่บังคับ)</label>
            <input
              name="description"
              type="text"
              placeholder="เช่น ไรเดอร์เติมเงินชำระหนี้"
              className="w-full px-3 py-2.5 rounded-lg border border-outline-variant bg-surface-container text-on-surface text-body-md focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          {state.error && (
            <p className="text-error text-body-sm bg-error-container/20 px-3 py-2 rounded-lg">{state.error}</p>
          )}
          {state.success && (
            <p className="text-green-700 text-body-sm bg-green-50 px-3 py-2 rounded-lg">
              บันทึกรายการสำเร็จ ยอดคงเหลือ: ฿{state.balance?.toFixed(2)}
            </p>
          )}

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose}
              className="flex-1 py-2.5 rounded-full border border-outline-variant text-on-surface text-label-lg hover:bg-surface-container transition-colors">
              ยกเลิก
            </button>
            <button type="submit" disabled={pending}
              className="flex-1 py-2.5 rounded-full bg-orange-500 text-white text-label-lg hover:bg-orange-600 transition-colors disabled:opacity-60">
              {pending ? 'กำลังบันทึก...' : 'ยืนยันเติมเงิน'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── History Modal ─────────────────────────────────────────────────────────────
function HistoryModal({ rider, onClose }: { rider: Rider; onClose: () => void }) {
  const [transactions, setTransactions] = useState<RiderWalletTransaction[] | null>(null)
  const [isPending, startTransition] = useTransition()

  useEffect(() => {
    startTransition(async () => {
      try {
        const data = await fetchRiderTransactions(rider.id)
        setTransactions(data)
      } catch {
        setTransactions([])
      }
    })
  }, [rider.id])

  const TYPE_LABEL: Record<string, string> = {
    advance:   'บริษัทออกเงิน',
    topup:     'ไรเดอร์เติมเงิน',
    deduction: 'หัก',
  }
  const TYPE_COLOR: Record<string, string> = {
    advance:   'text-orange-500 bg-orange-50',
    topup:     'text-on-surface bg-surface-container',
    deduction: 'text-orange-500 bg-orange-50',
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
      <div className="bg-surface-container-lowest rounded-2xl shadow-2xl border border-outline-variant max-h-[80vh] flex flex-col" style={{ width: 'min(520px, calc(100vw - 2rem))' }}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-outline-variant shrink-0">
          <div>
            <h3 className="text-title-lg text-on-surface">ประวัติธุรกรรม</h3>
            <p className="text-body-sm text-on-surface-variant">{rider.name} · {rider.phone}</p>
          </div>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-surface-container text-on-surface-variant">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {isPending || transactions === null ? (
            <div className="flex justify-center py-8 text-on-surface-variant">
              <span className="material-symbols-outlined animate-spin">progress_activity</span>
            </div>
          ) : transactions.length === 0 ? (
            <p className="text-center text-on-surface-variant text-body-md py-8">ยังไม่มีประวัติธุรกรรม</p>
          ) : (
            <div className="flex flex-col gap-2">
              {transactions.map(tx => (
                <div key={tx.id} className="flex items-start justify-between gap-3 p-3 rounded-xl bg-surface-container hover:bg-surface-bright transition-colors">
                  <div className="flex items-center gap-3">
                    <span className={`text-label-sm px-2 py-0.5 rounded-full font-medium ${TYPE_COLOR[tx.type] ?? 'text-on-surface-variant bg-surface-container'}`}>
                      {TYPE_LABEL[tx.type] ?? tx.type}
                    </span>
                    <span className="text-body-sm text-on-surface-variant">{tx.description}</span>
                  </div>
                  <div className="text-right shrink-0">
                    <p className={`text-label-lg font-semibold ${tx.type === 'advance' ? 'text-orange-500' : 'text-on-surface'}`}>
                      {tx.type === 'advance' ? '-' : '+'}฿{tx.amount.toFixed(2)}
                    </p>
                    <p className="text-label-sm text-on-surface-variant">
                      {new Date(tx.created_at).toLocaleString('th-TH', {
                        day: '2-digit', month: 'short', year: '2-digit', hour: '2-digit', minute: '2-digit',
                      })}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-outline-variant shrink-0">
          <button onClick={onClose}
            className="w-full py-2.5 rounded-full border border-outline-variant text-on-surface text-label-lg hover:bg-surface-container transition-colors">
            ปิด
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Main Export: Table + Buttons + Modal Controller ──────────────────────────
export default function RiderWalletClient({
  rows,
  allRiders,
}: {
  rows: RiderWalletRow[]
  allRiders: Rider[]
}) {
  const [modal, setModal] = useState<{ type: 'advance' | 'topup' | 'history'; rider?: Rider } | null>(null)

  return (
    <>
      {/* Action buttons row */}
      <div className="flex gap-3 mb-4 flex-wrap">
        <button
          onClick={() => setModal({ type: 'advance' })}
          className="flex items-center gap-2 px-4 py-2.5 bg-orange-500 text-white text-label-lg rounded-full hover:bg-orange-600 transition-colors shadow-sm"
        >
          <span className="material-symbols-outlined text-sm">account_balance_wallet</span>
          ออกเงินล่วงหน้า
        </button>
        <button
          onClick={() => setModal({ type: 'topup' })}
          className="flex items-center gap-2 px-4 py-2.5 bg-orange-500 text-white text-label-lg rounded-full hover:bg-orange-600 transition-colors shadow-sm"
        >
          <span className="material-symbols-outlined text-sm">add_circle</span>
          บันทึกการเติมเงิน
        </button>
      </div>

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse min-w-180">
          <thead>
            <tr className="border-b border-surface-container bg-surface-bright">
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">ไรเดอร์</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">เบอร์โทร</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">ยอดคงเหลือ</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">บริษัทออกไปทั้งหมด</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">ไรเดอร์เติมมา</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider">ล่าสุด</th>
              <th className="text-label-md text-on-surface-variant py-3 px-6 uppercase tracking-wider text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-surface-container">
            {rows.length === 0 ? (
              <tr>
                <td colSpan={7} className="py-12 text-center text-on-surface-variant text-body-md">
                  ยังไม่มีประวัติการออกเงินล่วงหน้า
                </td>
              </tr>
            ) : rows.map(r => {
              const riderRef: Rider = { id: r.id, name: r.name, phone: r.phone }
              const isNegative = r.balance < 0
              return (
                <tr key={r.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-6">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center text-on-surface font-bold text-sm shrink-0">
                        {r.name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()}
                      </div>
                      <span className="text-label-lg text-on-background">{r.name}</span>
                    </div>
                  </td>
                  <td className="py-4 px-6 text-body-md text-on-surface">{r.phone || '—'}</td>
                  <td className="py-4 px-6 text-right">
                    <span className={`text-label-lg font-semibold ${isNegative ? 'text-orange-500' : 'text-on-surface'}`}>
                      {isNegative ? '-' : '+'}฿{Math.abs(r.balance).toFixed(2)}
                    </span>
                    {isNegative && (
                      <span className="ml-1.5 text-label-sm text-orange-500 bg-orange-50 px-1.5 py-0.5 rounded-full">ติดหนี้</span>
                    )}
                  </td>
                  <td className="py-4 px-6 text-right text-body-md text-on-surface">
                    ฿{r.total_advanced.toFixed(2)}
                  </td>
                  <td className="py-4 px-6 text-right text-body-md text-on-surface">
                    ฿{r.total_topup.toFixed(2)}
                  </td>
                  <td className="py-4 px-6 text-body-sm text-on-surface-variant">
                    {r.last_transaction_at
                      ? new Date(r.last_transaction_at).toLocaleDateString('th-TH', {
                          day: '2-digit', month: 'short', year: '2-digit',
                        })
                      : '—'}
                  </td>
                  <td className="py-4 px-6 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => setModal({ type: 'advance', rider: riderRef })}
                        className="p-1.5 rounded-lg hover:bg-orange-50 text-orange-500 transition-colors"
                        title="ออกเงินล่วงหน้า"
                      >
                        <span className="material-symbols-outlined text-[18px]">account_balance_wallet</span>
                      </button>
                      <button
                        onClick={() => setModal({ type: 'topup', rider: riderRef })}
                        className="p-1.5 rounded-lg hover:bg-orange-50 text-orange-500 transition-colors"
                        title="เติมเงิน"
                      >
                        <span className="material-symbols-outlined text-[18px]">add_circle</span>
                      </button>
                      <button
                        onClick={() => setModal({ type: 'history', rider: riderRef })}
                        className="p-1.5 rounded-lg hover:bg-surface-container text-on-surface-variant transition-colors"
                        title="ประวัติ"
                      >
                        <span className="material-symbols-outlined text-[18px]">history</span>
                      </button>
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Modals */}
      {modal?.type === 'advance' && (
        <AdvanceModal
          riders={allRiders}
          defaultRider={modal.rider}
          onClose={() => setModal(null)}
        />
      )}
      {modal?.type === 'topup' && (
        <TopupModal
          riders={allRiders}
          defaultRider={modal.rider}
          onClose={() => setModal(null)}
        />
      )}
      {modal?.type === 'history' && modal.rider && (
        <HistoryModal
          rider={modal.rider}
          onClose={() => setModal(null)}
        />
      )}
    </>
  )
}
