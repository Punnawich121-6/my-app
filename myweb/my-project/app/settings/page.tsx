'use client'

import { useState, useEffect, useCallback, useRef } from 'react'
import Navbar from '../component/navbar'

// ---------- Types ----------
type Settings = {
  platformName: string
  supportEmail: string
  defaultCurrency: string
  systemLanguage: string
  maxDeliveryRadius: string
  baseServiceFee: string
  restaurantCommission: string
  twoFactorAuth: string
  strictPasswordPolicy: string
  sessionTimeout: string
  emailNotifications: string
  smsNotifications: string
  marketingPush: string
}

type Admin = {
  id: string
  name: string
  email: string
  role: string
  isActive: number
}

type Toast = { id: number; message: string; type: 'success' | 'error' }

const DEFAULT: Settings = {
  platformName: 'Zest & Savory',
  supportEmail: 'support@zestandsavory.com',
  defaultCurrency: 'USD',
  systemLanguage: 'en',
  maxDeliveryRadius: '12.5',
  baseServiceFee: '2.99',
  restaurantCommission: '15',
  twoFactorAuth: 'true',
  strictPasswordPolicy: 'true',
  sessionTimeout: '30',
  emailNotifications: 'true',
  smsNotifications: 'true',
  marketingPush: 'false',
}

const ROLES = ['Super Admin', 'Manager', 'Editor']

// ---------- Sub-components ----------

function Toggle({ checked, onChange }: { checked: boolean; onChange: (v: boolean) => void }) {
  return (
    <label className="relative inline-flex items-center cursor-pointer">
      <input
        checked={checked}
        onChange={e => onChange(e.target.checked)}
        className="sr-only peer"
        type="checkbox"
      />
      <div className="w-11 h-6 bg-surface-variant rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary" />
    </label>
  )
}

function ToastBar({ toasts, dismiss }: { toasts: Toast[]; dismiss: (id: number) => void }) {
  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2">
      {toasts.map(t => (
        <div
          key={t.id}
          className={`flex items-center gap-3 px-4 py-3 rounded-2xl shadow-lg text-white text-body-sm font-semibold min-w-[220px] transition-all
            ${t.type === 'success' ? 'bg-tertiary' : 'bg-error'}`}
        >
          <span className="material-symbols-outlined text-[20px]">
            {t.type === 'success' ? 'check_circle' : 'error'}
          </span>
          <span className="flex-1">{t.message}</span>
          <button onClick={() => dismiss(t.id)} className="opacity-70 hover:opacity-100">
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>
      ))}
    </div>
  )
}

// ---------- Main Page ----------
export default function Settings() {
  const [settings, setSettings] = useState<Settings>(DEFAULT)
  const [saved, setSaved] = useState<Settings>(DEFAULT)
  const [admins, setAdmins] = useState<Admin[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [toasts, setToasts] = useState<Toast[]>([])
  const toastId = useRef(0)

  // Modal states
  const [showModal, setShowModal] = useState(false)
  const [editingAdmin, setEditingAdmin] = useState<Admin | null>(null)
  const [formName, setFormName] = useState('')
  const [formEmail, setFormEmail] = useState('')
  const [formPassword, setFormPassword] = useState('')
  const [formRole, setFormRole] = useState('Editor')
  const [formActive, setFormActive] = useState(true)
  const [modalSaving, setModalSaving] = useState(false)

  // Actions dropdown
  const [openDropdown, setOpenDropdown] = useState<string | null>(null)
  const dropdownRef = useRef<HTMLDivElement>(null)

  // Delete confirm
  const [deletingAdmin, setDeletingAdmin] = useState<Admin | null>(null)

  // ---------- Toast helpers ----------
  const addToast = useCallback((message: string, type: 'success' | 'error') => {
    const id = ++toastId.current
    setToasts(prev => [...prev, { id, message, type }])
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4000)
  }, [])

  const dismissToast = (id: number) => setToasts(prev => prev.filter(t => t.id !== id))

  // ---------- Load data ----------
  useEffect(() => {
    async function load() {
      try {
        const [sRes, aRes] = await Promise.all([
          fetch('/api/settings'),
          fetch('/api/settings/admins'),
        ])
        if (sRes.ok) {
          const s = await sRes.json()
          setSettings(s)
          setSaved(s)
        }
        if (aRes.ok) {
          setAdmins(await aRes.json())
        }
      } catch {
        addToast('Failed to load settings', 'error')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [addToast])

  // Close dropdown on outside click
  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setOpenDropdown(null)
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [])

  // ---------- Settings helpers ----------
  const set = (key: keyof Settings, value: string) =>
    setSettings(prev => ({ ...prev, [key]: value }))

  const setBool = (key: keyof Settings, value: boolean) =>
    set(key, value ? 'true' : 'false')

  const bool = (key: keyof Settings) => settings[key] === 'true'

  // ---------- Save / Discard ----------
  async function handleSave() {
    setSaving(true)
    try {
      const res = await fetch('/api/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(settings),
      })
      if (!res.ok) throw new Error()
      setSaved(settings)
      addToast('Configuration saved successfully', 'success')
    } catch {
      addToast('Failed to save configuration', 'error')
    } finally {
      setSaving(false)
    }
  }

  function handleDiscard() {
    setSettings(saved)
    addToast('Changes discarded', 'success')
  }

  const isDirty = JSON.stringify(settings) !== JSON.stringify(saved)

  // ---------- Admin modal ----------
  function openAddModal() {
    setEditingAdmin(null)
    setFormName('')
    setFormEmail('')
    setFormPassword('')
    setFormRole('Editor')
    setFormActive(true)
    setShowModal(true)
  }

  function openEditModal(admin: Admin) {
    setOpenDropdown(null)
    setEditingAdmin(admin)
    setFormName(admin.name)
    setFormEmail(admin.email)
    setFormPassword('')
    setFormRole(admin.role)
    setFormActive(admin.isActive === 1)
    setShowModal(true)
  }

  async function handleModalSave() {
    if (!formEmail) { addToast('Email is required', 'error'); return }
    if (!editingAdmin && !formPassword) { addToast('Password is required', 'error'); return }

    setModalSaving(true)
    try {
      if (editingAdmin) {
        const res = await fetch(`/api/settings/admins/${editingAdmin.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: formName, email: formEmail, role: formRole, isActive: formActive }),
        })
        if (!res.ok) throw new Error()
        setAdmins(prev => prev.map(a => a.id === editingAdmin.id
          ? { ...a, name: formName, email: formEmail, role: formRole, isActive: formActive ? 1 : 0 }
          : a
        ))
        addToast('Admin updated successfully', 'success')
      } else {
        const res = await fetch('/api/settings/admins', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ name: formName, email: formEmail, password: formPassword, role: formRole }),
        })
        const data = await res.json()
        if (!res.ok) throw new Error(data.error || 'Failed')
        setAdmins(prev => [...prev, {
          id: data.id,
          name: formName || formEmail.split('@')[0],
          email: formEmail,
          role: formRole,
          isActive: 1,
        }])
        addToast('Admin user added successfully', 'success')
      }
      setShowModal(false)
    } catch (err: unknown) {
      addToast(err instanceof Error ? err.message : 'Operation failed', 'error')
    } finally {
      setModalSaving(false)
    }
  }

  // ---------- Delete admin ----------
  async function confirmDelete() {
    if (!deletingAdmin) return
    try {
      const res = await fetch(`/api/settings/admins/${deletingAdmin.id}`, { method: 'DELETE' })
      if (!res.ok) throw new Error()
      setAdmins(prev => prev.filter(a => a.id !== deletingAdmin.id))
      addToast('Admin user removed', 'success')
    } catch {
      addToast('Failed to remove admin', 'error')
    } finally {
      setDeletingAdmin(null)
    }
  }

  // ---------- Role badge style ----------
  function roleBadge(role: string) {
    if (role === 'Super Admin') return 'bg-primary-container/20 text-primary-fixed-dim'
    return 'bg-surface-container-high text-on-surface-variant'
  }

  // ---------- Initials ----------
  function initials(name: string) {
    return name.split(' ').map(w => w[0]).join('').slice(0, 2).toUpperCase()
  }

  if (loading) {
    return (
      <>
        <Navbar />
        <main className="pt-16 md:pl-64 min-h-screen flex items-center justify-center">
          <div className="flex flex-col items-center gap-3 text-on-surface-variant">
            <span className="material-symbols-outlined animate-spin text-4xl">progress_activity</span>
            <p className="text-body-md">Loading settings…</p>
          </div>
        </main>
      </>
    )
  }

  return (
    <>
      <Navbar />

      <main className="pt-16 md:pl-64 min-h-screen pb-20">
        <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">

          {/* Page Header */}
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div>
              <h2 className="text-headline-lg text-on-surface mb-2">System Settings</h2>
              <p className="text-body-md text-on-surface-variant">
                Manage platform configurations, security policies, and administrative access.
              </p>
            </div>
            <div className="flex gap-3">
              <button
                onClick={handleDiscard}
                disabled={!isDirty || saving}
                className="px-6 py-2.5 rounded-full border-2 border-primary text-primary text-label-lg font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                Discard Changes
              </button>
              <button
                onClick={handleSave}
                disabled={!isDirty || saving}
                className="px-6 py-2.5 rounded-full bg-primary-container text-on-primary-container text-label-lg font-bold shadow-[0_4px_12px_rgba(255,107,53,0.25)] hover:shadow-[0_6px_16px_rgba(255,107,53,0.35)] transition-shadow disabled:opacity-40 disabled:cursor-not-allowed flex items-center gap-2"
              >
                {saving && <span className="material-symbols-outlined animate-spin text-[18px]">progress_activity</span>}
                Save Configuration
              </button>
            </div>
          </div>

          {/* Bento Grid */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">

            {/* Left Column */}
            <div className="lg:col-span-7 flex flex-col gap-6">

              {/* General Settings */}
              <section className="bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(171,53,0,0.04)] border border-outline-variant/20 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-primary-container to-tertiary-container opacity-50" />
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">tune</span>
                  </div>
                  <h3 className="text-headline-sm text-on-surface">General Settings</h3>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Platform Name</label>
                    <input
                      className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all"
                      type="text"
                      value={settings.platformName}
                      onChange={e => set('platformName', e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Support Email</label>
                    <input
                      className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all"
                      type="email"
                      value={settings.supportEmail}
                      onChange={e => set('supportEmail', e.target.value)}
                    />
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Default Currency</label>
                    <div className="relative">
                      <select
                        className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none appearance-none"
                        value={settings.defaultCurrency}
                        onChange={e => set('defaultCurrency', e.target.value)}
                      >
                        <option value="USD">USD ($)</option>
                        <option value="EUR">EUR (€)</option>
                        <option value="GBP">GBP (£)</option>
                        <option value="THB">THB (฿)</option>
                      </select>
                      <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">expand_more</span>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">System Language</label>
                    <div className="relative">
                      <select
                        className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none appearance-none"
                        value={settings.systemLanguage}
                        onChange={e => set('systemLanguage', e.target.value)}
                      >
                        <option value="en">English (US)</option>
                        <option value="es">Spanish</option>
                        <option value="fr">French</option>
                        <option value="th">Thai</option>
                      </select>
                      <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">expand_more</span>
                    </div>
                  </div>
                </div>
              </section>

              {/* Operational Rules */}
              <section className="bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(171,53,0,0.04)] border border-outline-variant/20">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">rule</span>
                  </div>
                  <h3 className="text-headline-sm text-on-surface">Operational Rules</h3>
                </div>
                <div className="space-y-6">
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant flex justify-between">
                      <span>Max Delivery Radius (km)</span>
                      <span className="text-primary font-bold">{settings.maxDeliveryRadius} km</span>
                    </label>
                    <input
                      className="w-full h-2 bg-surface-container-highest rounded-lg appearance-none cursor-pointer accent-primary"
                      max="50"
                      min="1"
                      step="0.5"
                      type="range"
                      value={settings.maxDeliveryRadius}
                      onChange={e => set('maxDeliveryRadius', e.target.value)}
                    />
                    <div className="flex justify-between text-label-sm text-on-surface-variant mt-1">
                      <span>1 km</span><span>50 km</span>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4 border-t border-outline-variant/30">
                    <div className="space-y-2">
                      <label className="text-label-md text-on-surface-variant block">Base Service Fee</label>
                      <div className="relative">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant font-bold">$</span>
                        <input
                          className="w-full bg-surface-container pl-8 pr-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all"
                          step="0.01"
                          min="0"
                          type="number"
                          value={settings.baseServiceFee}
                          onChange={e => set('baseServiceFee', e.target.value)}
                        />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <label className="text-label-md text-on-surface-variant block">Restaurant Commission</label>
                      <div className="relative">
                        <input
                          className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all"
                          step="1"
                          min="0"
                          max="100"
                          type="number"
                          value={settings.restaurantCommission}
                          onChange={e => set('restaurantCommission', e.target.value)}
                        />
                        <span className="absolute right-4 top-1/2 -translate-y-1/2 text-on-surface-variant font-bold">%</span>
                      </div>
                    </div>
                  </div>
                </div>
              </section>
            </div>

            {/* Right Column */}
            <div className="lg:col-span-5 flex flex-col gap-6">

              {/* Security */}
              <section className="bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(171,53,0,0.04)] border border-outline-variant/20">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">shield_lock</span>
                  </div>
                  <h3 className="text-headline-sm text-on-surface">Security</h3>
                </div>
                <div className="space-y-5">
                  <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
                    <div>
                      <p className="text-body-md text-on-surface font-semibold">Two-Factor Auth (2FA)</p>
                      <p className="text-label-sm text-on-surface-variant">Require for all admins</p>
                    </div>
                    <Toggle checked={bool('twoFactorAuth')} onChange={v => setBool('twoFactorAuth', v)} />
                  </div>
                  <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
                    <div>
                      <p className="text-body-md text-on-surface font-semibold">Strict Password Policy</p>
                      <p className="text-label-sm text-on-surface-variant">Min 12 chars, symbols</p>
                    </div>
                    <Toggle checked={bool('strictPasswordPolicy')} onChange={v => setBool('strictPasswordPolicy', v)} />
                  </div>
                  <div className="space-y-2 pt-2">
                    <label className="text-label-md text-on-surface-variant block">Session Timeout (Minutes)</label>
                    <input
                      className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all"
                      type="number"
                      min="5"
                      max="1440"
                      value={settings.sessionTimeout}
                      onChange={e => set('sessionTimeout', e.target.value)}
                    />
                  </div>
                </div>
              </section>

              {/* Notifications */}
              <section className="bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(171,53,0,0.04)] border border-outline-variant/20">
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">notifications_active</span>
                  </div>
                  <h3 className="text-headline-sm text-on-surface">Master Alerts</h3>
                </div>
                <div className="space-y-4">
                  {[
                    { icon: 'mail', label: 'System Emails', key: 'emailNotifications' as keyof Settings },
                    { icon: 'sms', label: 'SMS Notifications', key: 'smsNotifications' as keyof Settings },
                    { icon: 'campaign', label: 'Marketing Push', key: 'marketingPush' as keyof Settings },
                  ].map((item, i, arr) => (
                    <div
                      key={item.key}
                      className={`flex items-center justify-between${i < arr.length - 1 ? ' border-b border-outline-variant/30 pb-4' : ''}`}
                    >
                      <div className="flex items-center gap-3">
                        <span className="material-symbols-outlined text-on-surface-variant">{item.icon}</span>
                        <span className="text-body-md text-on-surface">{item.label}</span>
                      </div>
                      <Toggle checked={bool(item.key)} onChange={v => setBool(item.key, v)} />
                    </div>
                  ))}
                </div>
              </section>
            </div>

            {/* Admin Access — full width */}
            <div className="lg:col-span-12" ref={dropdownRef}>
              <section className="bg-surface-container-lowest rounded-3xl p-6 shadow-[0_4px_16px_rgba(171,53,0,0.04)] border border-outline-variant/20">
                <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                      <span className="material-symbols-outlined">group</span>
                    </div>
                    <div>
                      <h3 className="text-headline-sm text-on-surface">Admin Access</h3>
                      <p className="text-label-sm text-on-surface-variant">Manage team roles and permissions</p>
                    </div>
                  </div>
                  <button
                    onClick={openAddModal}
                    className="px-5 py-2 rounded-full bg-surface-container-high text-on-surface text-label-lg shadow-sm hover:bg-surface-container-highest transition-colors flex items-center gap-2 border border-outline-variant"
                  >
                    <span className="material-symbols-outlined text-[18px]">person_add</span>
                    Add User
                  </button>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-outline-variant/30 text-label-md text-on-surface-variant">
                        <th className="pb-3 pl-2 font-semibold">User</th>
                        <th className="pb-3 font-semibold">Email</th>
                        <th className="pb-3 font-semibold">Role</th>
                        <th className="pb-3 font-semibold">Status</th>
                        <th className="pb-3 pr-2 text-right font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="text-body-sm">
                      {admins.length === 0 ? (
                        <tr>
                          <td colSpan={5} className="py-8 text-center text-on-surface-variant text-body-sm">
                            No admin users found
                          </td>
                        </tr>
                      ) : admins.map((a, i) => (
                        <tr
                          key={a.id}
                          className={`${i < admins.length - 1 ? 'border-b border-outline-variant/10' : ''} hover:bg-surface-container-low/50 transition-colors group`}
                        >
                          <td className="py-4 pl-2">
                            <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-full bg-tertiary-container text-on-tertiary-container flex items-center justify-center font-bold text-label-md">
                                {initials(a.name)}
                              </div>
                              <span className="font-semibold text-on-surface">{a.name}</span>
                            </div>
                          </td>
                          <td className="py-4 text-on-surface-variant">{a.email}</td>
                          <td className="py-4">
                            <span className={`px-3 py-1 rounded-full text-label-md ${roleBadge(a.role)}`}>{a.role}</span>
                          </td>
                          <td className="py-4">
                            {a.isActive ? (
                              <div className="flex items-center gap-1.5 text-tertiary">
                                <div className="w-2 h-2 rounded-full bg-tertiary" />
                                <span className="font-medium">Active</span>
                              </div>
                            ) : (
                              <div className="flex items-center gap-1.5 text-on-surface-variant opacity-70">
                                <div className="w-2 h-2 rounded-full bg-outline" />
                                <span className="font-medium">Offline</span>
                              </div>
                            )}
                          </td>
                          <td className="py-4 pr-2 text-right relative">
                            <button
                              onClick={() => setOpenDropdown(openDropdown === a.id ? null : a.id)}
                              className="text-on-surface-variant hover:text-primary transition-colors opacity-0 group-hover:opacity-100"
                            >
                              <span className="material-symbols-outlined">more_vert</span>
                            </button>
                            {openDropdown === a.id && (
                              <div className="absolute right-8 top-3 z-10 bg-surface-container-lowest border border-outline-variant/30 rounded-2xl shadow-lg overflow-hidden min-w-[140px]">
                                <button
                                  onClick={() => openEditModal(a)}
                                  className="w-full flex items-center gap-2 px-4 py-3 text-on-surface hover:bg-surface-container-low text-body-sm transition-colors"
                                >
                                  <span className="material-symbols-outlined text-[18px]">edit</span>
                                  Edit
                                </button>
                                <button
                                  onClick={() => { setDeletingAdmin(a); setOpenDropdown(null) }}
                                  className="w-full flex items-center gap-2 px-4 py-3 text-error hover:bg-error-container/20 text-body-sm transition-colors"
                                >
                                  <span className="material-symbols-outlined text-[18px]">delete</span>
                                  Remove
                                </button>
                              </div>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>
            </div>
          </div>
        </div>
      </main>

      {/* Add / Edit Admin Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-surface-container-lowest rounded-3xl shadow-2xl border border-outline-variant" style={{ width: 'min(calc(100vw - 2rem), 32rem)' }}>
            <div className="overflow-y-auto max-h-[90vh] p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-on-surface">
                {editingAdmin ? 'Edit Admin User' : 'Add Admin User'}
              </h3>
              <button onClick={() => setShowModal(false)} className="text-on-surface-variant hover:text-on-surface transition-colors">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-on-surface-variant mb-1.5">Full Name</label>
                <input
                  type="text"
                  placeholder="e.g. Sarah Jenkins"
                  value={formName}
                  onChange={e => setFormName(e.target.value)}
                  className="block w-full px-4 py-3 rounded-xl border border-outline-variant bg-surface-container text-sm text-on-surface placeholder:text-on-surface-variant/60 focus:outline-none focus:border-orange-400 focus:ring-2 focus:ring-orange-400/20 transition-all"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-on-surface-variant mb-1.5">
                  Email <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  placeholder="admin@example.com"
                  value={formEmail}
                  onChange={e => setFormEmail(e.target.value)}
                  className="block w-full px-4 py-3 rounded-xl border border-outline-variant bg-surface-container text-sm text-on-surface placeholder:text-on-surface-variant/60 focus:outline-none focus:border-orange-400 focus:ring-2 focus:ring-orange-400/20 transition-all"
                />
              </div>
              {!editingAdmin && (
                <div>
                  <label className="block text-sm font-medium text-on-surface-variant mb-1.5">
                    Password <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="password"
                    placeholder="Min 8 characters"
                    value={formPassword}
                    onChange={e => setFormPassword(e.target.value)}
                    className="block w-full px-4 py-3 rounded-xl border border-outline-variant bg-surface-container text-sm text-on-surface placeholder:text-on-surface-variant/60 focus:outline-none focus:border-orange-400 focus:ring-2 focus:ring-orange-400/20 transition-all"
                  />
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-on-surface-variant mb-1.5">Role</label>
                <div className="relative">
                  <select
                    value={formRole}
                    onChange={e => setFormRole(e.target.value)}
                    className="block w-full px-4 py-3 rounded-xl border border-outline-variant bg-surface-container text-sm text-on-surface focus:outline-none focus:border-orange-400 focus:ring-2 focus:ring-orange-400/20 appearance-none transition-all"
                  >
                    {ROLES.map(r => <option key={r} value={r}>{r}</option>)}
                  </select>
                  <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">expand_more</span>
                </div>
              </div>
              {editingAdmin && (
                <div className="flex items-center justify-between p-4 bg-surface-container rounded-xl border border-outline-variant">
                  <div>
                    <p className="text-sm font-semibold text-on-surface">Account Active</p>
                    <p className="text-xs text-on-surface-variant mt-0.5">Allow this user to log in</p>
                  </div>
                  <Toggle checked={formActive} onChange={setFormActive} />
                </div>
              )}
            </div>
            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 px-4 py-2.5 rounded-full border-2 border-outline-variant text-on-surface-variant text-sm font-bold hover:bg-surface-container transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleModalSave}
                disabled={modalSaving}
                className="flex-1 px-4 py-2.5 rounded-full bg-orange-500 text-white text-sm font-bold hover:bg-orange-600 transition-colors disabled:opacity-50 flex items-center justify-center gap-2 shadow-sm"
              >
                {modalSaving && <span className="material-symbols-outlined animate-spin text-[18px]">progress_activity</span>}
                {editingAdmin ? 'Save Changes' : 'Add User'}
              </button>
            </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deletingAdmin && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-surface-container-lowest rounded-3xl p-6 w-full max-w-sm shadow-2xl border border-outline-variant/20 text-center">
            <div className="w-14 h-14 rounded-full bg-error-container flex items-center justify-center mx-auto mb-4">
              <span className="material-symbols-outlined text-error text-2xl">delete_forever</span>
            </div>
            <h3 className="text-headline-sm text-on-surface mb-2">Remove Admin?</h3>
            <p className="text-body-md text-on-surface-variant mb-6">
              <span className="font-semibold text-on-surface">{deletingAdmin.name}</span> will lose all access to the admin portal immediately.
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setDeletingAdmin(null)}
                className="flex-1 px-4 py-2.5 rounded-full border-2 border-outline-variant text-on-surface-variant text-label-lg font-bold hover:bg-surface-container transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 px-4 py-2.5 rounded-full bg-error text-on-error text-label-lg font-bold hover:shadow-md transition-shadow"
              >
                Remove
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toasts */}
      <ToastBar toasts={toasts} dismiss={dismissToast} />
    </>
  )
}
