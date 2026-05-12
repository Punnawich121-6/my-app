'use client' // บอกว่าไฟล์นี้ทำงานที่ฝั่ง Browser (Client-side) เพราะมีการใช้ Hook อย่าง useEffect
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'


export default function AutoRefresh({ interval }: { interval: number }) {
  const router = useRouter()

  useEffect(() => {
    // สร้างตัวจับเวลา (Timer) ให้ทำงานทุกๆ 'interval' มิลลิวินาที
    const id = setInterval(() => {
      router.refresh() // Next.js ไปดึงข้อมูลจาก Server ใหม่ (แต่ไม่รีโหลดหน้าเว็บทั้งหมด)
    }, interval)

    // Cleanup Function
    return () => clearInterval(id)
    
  }, [interval, router]) // จะเริ่มทำงานใหม่ถ้าค่า interval หรือ router เปลี่ยนแปลง

  // Component นี้ไม่มีหน้าตา (UI) จึงส่งค่ากลับเป็น null
  return null
}