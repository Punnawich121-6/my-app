'use client'

import { useActionState, useState } from 'react'
import { approveLoanRequest, rejectLoanRequest } from '@/app/actions/riderWallet'
import type { RiderLoanRequest } from '@/app/lib/riderWallet'

const initState = { success: false, error: null }

function LoanCard({ loan }: { loan: RiderLoanRequest }) {
  const [approveState, approveAction, approvePending] = useActionState(approveLoanRequest, initState)
  const [rejectState, rejectAction, rejectPending]   = useActionState(rejectLoanRequest, initState)
  const [showNote, setShowNote] = useState(false)

  const isNegative = loan.current_balance < 0

  return (
    <div className="bg-surface-container-lowest rounded-xl border border-surface-container p-5 flex flex-col gap-3">
      {/* Rider info */}
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-orange-50 flex items-center justify-center text-orange-500 font-bold text-sm shrink-0">
          {loan.rider_name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase()}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-label-lg text-on-surface font-semibold">{loan.rider_name}</p>
          <p className="text-body-sm text-on-surface-variant">{loan.rider_phone}</p>
        </div>
        <div className="text-right shrink-0">
          <p className="text-headline-sm text-on-surface font-bold">฿{loan.amount.toLocaleString('th-TH', { minimumFractionDigits: 2 })}</p>
          <p className={`text-label-sm ${isNegative ? 'text-orange-500' : 'text-on-surface-variant'}`}>
            ยอดปัจจุบัน: {isNegative ? '-' : ''}฿{Math.abs(loan.current_balance).toFixed(2)}
          </p>
        </div>
      </div>

      {/* Reason */}
      {loan.reason && (
        <div className="bg-surface-container px-3 py-2 rounded-lg text-body-sm text-on-surface-variant">
          <span className="font-medium text-on-surface">เหตุผล:</span> {loan.reason}
        </div>
      )}

      {/* Time */}
      <p className="text-label-sm text-on-surface-variant">
        ส่งคำขอ: {new Date(loan.created_at).toLocaleDateString('th-TH', { day: '2-digit', month: 'short', year: '2-digit', hour: '2-digit', minute: '2-digit' })}
      </p>

      {/* Success state */}
      {(approveState.success || rejectState.success) && (
        <p className="text-body-sm text-orange-600 bg-orange-50 px-3 py-2 rounded-lg">
          {approveState.success ? '✓ อนุมัติแล้ว' : '✓ ปฏิเสธแล้ว'}
        </p>
      )}
      {(approveState.error || rejectState.error) && (
        <p className="text-body-sm text-on-surface-variant bg-surface-container px-3 py-2 rounded-lg">
          {approveState.error || rejectState.error}
        </p>
      )}

      {/* Action area */}
      {!approveState.success && !rejectState.success && (
        <>
          {showNote ? (
            <form action={approveAction} className="flex flex-col gap-2">
              <input type="hidden" name="loan_id" value={loan.id} />
              <input
                name="admin_note"
                type="text"
                placeholder="หมายเหตุ Admin (ไม่บังคับ)"
                className="w-full px-3 py-2 rounded-lg border border-outline-variant bg-surface-container text-body-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-orange-400"
              />
              <div className="flex gap-2">
                <button type="button" onClick={() => setShowNote(false)}
                  className="flex-1 py-2 rounded-full border border-outline-variant text-on-surface text-label-md hover:bg-surface-container transition-colors">
                  ยกเลิก
                </button>
                <button type="submit" disabled={approvePending}
                  className="flex-1 py-2 rounded-full bg-orange-500 text-white text-label-md hover:bg-orange-600 transition-colors disabled:opacity-60">
                  {approvePending ? 'กำลังบันทึก...' : 'ยืนยันอนุมัติ'}
                </button>
              </div>
            </form>
          ) : (
            <div className="flex gap-2">
              {/* Reject */}
              <form action={rejectAction} className="flex-1">
                <input type="hidden" name="loan_id" value={loan.id} />
                <input type="hidden" name="admin_note" value="" />
                <button type="submit" disabled={rejectPending}
                  className="w-full py-2 rounded-full border border-outline-variant text-on-surface-variant text-label-md hover:bg-surface-container transition-colors disabled:opacity-60">
                  {rejectPending ? '...' : 'ปฏิเสธ'}
                </button>
              </form>
              {/* Approve */}
              <button onClick={() => setShowNote(true)}
                className="flex-1 py-2 rounded-full bg-orange-500 text-white text-label-md hover:bg-orange-600 transition-colors">
                อนุมัติ
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}

export default function RiderLoanApprovals({ loans }: { loans: RiderLoanRequest[] }) {
  if (loans.length === 0) return null

  return (
    <div className="bg-orange-50 border border-orange-200 rounded-xl p-5 mb-6">
      <div className="flex items-center gap-2 mb-4">
        <span className="material-symbols-outlined text-orange-500">handshake</span>
        <h4 className="text-title-md text-orange-700 font-semibold">คำขอยืมเงิน รออนุมัติ</h4>
        <span className="ml-auto bg-orange-500 text-white text-label-sm px-2 py-0.5 rounded-full">
          {loans.length} รายการ
        </span>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {loans.map(loan => <LoanCard key={loan.id} loan={loan} />)}
      </div>
    </div>
  )
}
