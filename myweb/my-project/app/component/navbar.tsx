"use client";

import { logout } from '@/app/actions/auth'
import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import ExportModal from "./ExportModal";
import SearchBar from "./SearchBar";
import NotificationBell from "./NotificationBell";

const navItems = [
  { label: "Dashboard",         icon: "dashboard",        href: "/dashboard" },
  { label: "Live Orders",       icon: "receipt_long",     href: "/orders" },
  { label: "Restaurants",       icon: "restaurant",       href: "/restaurants" },
  { label: "Fleet Management",  icon: "delivery_dining",  href: "/fleet" },
  { label: "Financials",        icon: "payments",         href: "/financials" },
  { label: "Analytics AI",      icon: "insights",         href: "/analytics" },
  { label: "Dispute Autopilot", icon: "gavel",            href: "/disputes" },
  { label: "Support Chat",      icon: "support_agent",    href: "/support" },
  { label: "System Settings",   icon: "settings",         href: "/settings" },
];

export default function Navbar() {
  const pathname    = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [exportOpen, setExportOpen] = useState(false);
  const [dark, setDark]             = useState(false);
  const [userOpen, setUserOpen]     = useState(false);
  const userRef = useRef<HTMLDivElement>(null);

  /* ── restore dark preference ── */
  useEffect(() => {
    const saved = localStorage.getItem('theme') === 'dark';
    setDark(saved);
    document.documentElement.classList.toggle('dark', saved);
  }, []);

  /* ── close user dropdown on outside click ── */
  useEffect(() => {
    function handler(e: MouseEvent) {
      if (userRef.current && !userRef.current.contains(e.target as Node)) setUserOpen(false);
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  function toggleDark() {
    const next = !dark;
    setDark(next);
    document.documentElement.classList.toggle('dark', next);
    localStorage.setItem('theme', next ? 'dark' : 'light');
  }

  /* shared class strings */
  const navLinkBase = "flex items-center gap-3 px-4 py-3 transition-colors duration-200 text-on-surface-variant hover:text-primary-container hover:bg-surface-container";
  const navLinkActive = "text-primary-container font-semibold border-r-4 border-primary-container bg-primary-container/10";

  return (
    <>
      {/* ── Side Nav ── */}
      <nav className={`
        bg-surface-container-lowest font-['Plus_Jakarta_Sans'] antialiased
        h-screen w-64 border-r border-surface-container-highest shadow-sm
        flex flex-col py-6 fixed left-0 top-0 transition-transform duration-300
        ${mobileOpen ? "translate-x-0" : "-translate-x-full"} md:translate-x-0
      `}>
        {/* Logo */}
        <div className="px-6 mb-8 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-primary-container flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-white" data-weight="fill">restaurant_menu</span>
          </div>
          <div>
            <h1 className="text-xl font-bold text-primary-container tracking-tight">Zest &amp; Savory</h1>
            <p className="text-[10px] font-bold tracking-wider text-on-surface-variant">Admin Portal</p>
          </div>
        </div>

        {/* Main Nav */}
        <div className="flex-1 mt-1">
          <ul className="space-y-1">
            {navItems.map(({ label, icon, href }) => {
              const active = pathname === href;
              return (
                <li key={href}>
                  <Link
                    href={href}
                    className={`${navLinkBase} ${active ? navLinkActive : ""}`}
                    onClick={() => setMobileOpen(false)}
                  >
                    <span className="material-symbols-outlined" {...(active ? { "data-weight": "fill" } : {})}>
                      {icon}
                    </span>
                    <span className="text-[14px] font-semibold leading-5 tracking-[0.02em]">{label}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>

        {/* Export */}
        <div className="px-6 mt-2 flex flex-col gap-2">
          <button
            onClick={() => setExportOpen(true)}
            className="w-full py-2.5 bg-primary-container text-white text-[14px] font-semibold rounded-full hover:bg-primary transition-colors shadow-sm flex items-center justify-center gap-2"
          >
            <span className="material-symbols-outlined text-[18px]">download</span>
            Export Reports
          </button>
          <form action={logout}>
            <button
              type="submit"
              className="w-full py-2.5 bg-error/10 text-error text-[14px] font-semibold rounded-full hover:bg-error/20 transition-colors flex items-center justify-center gap-2 border border-error/20"
            >
              <span className="material-symbols-outlined text-[18px]">logout</span>
              Logout
            </button>
          </form>
        </div>

      </nav>

      <ExportModal open={exportOpen} onClose={() => setExportOpen(false)} />

      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 bg-black/30 z-30 md:hidden" onClick={() => setMobileOpen(false)} />
      )}

      {/* ── Top Bar ── */}
      <header className="
        bg-surface-container-lowest/80 backdrop-blur-md font-['Plus_Jakarta_Sans'] text-sm font-medium
        fixed top-0 right-0 w-full md:w-[calc(100%-16rem)] z-30
        border-b border-surface-container-highest shadow-sm
        flex justify-between items-center px-4 md:px-8 h-16
      ">
        {/* Mobile hamburger */}
        <button
          className="md:hidden p-2 text-on-surface-variant hover:bg-surface-container rounded-full"
          onClick={() => setMobileOpen(v => !v)}
        >
          <span className="material-symbols-outlined">menu</span>
        </button>

        <div className="hidden md:block">
          <h2 className="text-[20px] font-semibold leading-7 text-on-background">Overview</h2>
        </div>

        <div className="flex items-center gap-2 md:gap-3">
          <SearchBar />
          <NotificationBell />

          {/* Dark mode */}
          <button
            onClick={toggleDark}
            className="text-on-surface-variant hover:bg-surface-container rounded-full p-2 hidden sm:flex items-center justify-center"
            title={dark ? 'Light mode' : 'Dark mode'}
          >
            <span className="material-symbols-outlined">{dark ? 'light_mode' : 'dark_mode'}</span>
          </button>

          {/* User profile */}
          <div ref={userRef} className="relative">
            <button
              onClick={() => setUserOpen(v => !v)}
              className="text-on-surface-variant hover:bg-surface-container rounded-full p-2 flex items-center justify-center"
            >
              <span className="material-symbols-outlined" data-weight="fill">account_circle</span>
            </button>

            {userOpen && (
              <div className="absolute right-0 top-full mt-2 w-52 bg-surface-container-lowest rounded-2xl shadow-xl border border-surface-container-highest z-50 overflow-hidden">
                <div className="px-4 py-3 border-b border-surface-container-highest">
                  <p className="text-sm font-semibold text-on-background">Admin</p>
                  <p className="text-xs text-on-surface-variant mt-0.5">Zest &amp; Savory Portal</p>
                </div>
                <ul className="py-1">
                  <li>
                    <Link
                      href="/settings"
                      onClick={() => setUserOpen(false)}
                      className="flex items-center gap-3 px-4 py-2.5 text-sm text-on-surface-variant hover:bg-surface-container hover:text-on-surface transition-colors"
                    >
                      <span className="material-symbols-outlined text-[18px]">settings</span>
                      Settings
                    </Link>
                  </li>
                  <li>
                    <button
                      onClick={toggleDark}
                      className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-on-surface-variant hover:bg-surface-container hover:text-on-surface transition-colors"
                    >
                      <span className="material-symbols-outlined text-[18px]">{dark ? 'light_mode' : 'dark_mode'}</span>
                      {dark ? 'Light Mode' : 'Dark Mode'}
                    </button>
                  </li>
                  <li className="border-t border-surface-container-highest mt-1">
                    <form action={logout}>
                      <button
                        type="submit"
                        className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-error hover:bg-error-container/30 transition-colors"
                      >
                        <span className="material-symbols-outlined text-[18px]">logout</span>
                        Sign out
                      </button>
                    </form>
                  </li>
                </ul>
              </div>
            )}
          </div>
        </div>
      </header>
    </>
  );
}
