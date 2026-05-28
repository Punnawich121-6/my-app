'use client'
import dynamic from 'next/dynamic'

const RiderLiveMap = dynamic(() => import('./RiderLiveMap'), { ssr: false })

export default RiderLiveMap
