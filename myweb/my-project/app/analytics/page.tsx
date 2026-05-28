import { redirect } from 'next/navigation'
import { verifySession } from '@/app/lib/session'
import Navbar from '../component/navbar'
import { getQuarterlyHistory } from '@/app/lib/analytics'
import AnalyticsClient from './AnalyticsClient'

export default async function AnalyticsPage() {
  const session = await verifySession()
  if (!session) redirect('/login')

  const history = await getQuarterlyHistory()

  const now = new Date()
  const currentYear  = now.getFullYear()
  const currentMonth = now.getMonth() + 1

  const defaultYear  = history[0]?.year  ?? currentYear
  const defaultMonth = history[0]
    ? (history[0].quarter - 1) * 3 + 1
    : currentMonth

  return (
    <>
      <Navbar />
      <main className="md:ml-64 pt-16 px-4 md:px-8 pb-12 min-h-screen">
        <div className="mt-8 mb-8">
          <h2 className="text-headline-lg text-on-background">Prescriptive Analytics</h2>
          <p className="text-body-md text-on-surface-variant mt-1">
            วิเคราะห์แนวโน้มและวางแผนธุรกิจ พร้อมคำแนะนำจาก AI
          </p>
        </div>
        <AnalyticsClient
          history={history}
          initialYear={defaultYear}
          initialMonth={defaultMonth}
        />
      </main>
    </>
  )
}
