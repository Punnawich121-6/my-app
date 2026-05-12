"use client";
import { useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";

const navItems = [
  { label: "Dashboard", icon: "dashboard", href: "/dashboard" },
  { label: "Live Orders", icon: "receipt_long", href: "/orders" },
  { label: "Restaurants", icon: "restaurant", href: "/restaurants" },
  { label: "Fleet Management", icon: "delivery_dining", href: "/fleet" },
  { label: "Financials", icon: "payments", href: "/financials" },
  { label: "System Settings", icon: "settings", href: "/settings" },
];

const bottomNavItems = [
  { label: "Help Center", icon: "help", href: "/help" }
];


export default function Navbar() {
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <>
      {/* Side NavBar */}
      <nav
        className={`
          bg-white font-['Plus_Jakarta_Sans'] antialiased h-screen w-64 border-r
          border-slate-200 shadow-sm flex flex-col py-6   fixed left-0 top-0
          transition-transform duration-300
          ${mobileOpen ? "translate-x-0" : "-translate-x-full"}
          md:translate-x-0
        `}
      >
        {/* Logo */}
        <div className="px-6 mb-8 flex items-center gap-3">

          <div className="w-10 h-10 rounded-lg bg-primary-container flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined  text-white" data-weight="fill">
              restaurant_menu
            </span>

          </div>

          <div>
            <h1 className="text-xl font-bold text-orange-600 tracking-tight">Zest &amp; Savory</h1>
            <p className="text-[10px] font-bold tracking-wider text-on-surface-variant">Admin Portal</p>
          </div>
          
        </div>

        {/* Main Nav */}
        <div className="flex-1 overflow-y-auto mt-4">
          <ul className="space-y-1">
            {navItems.map(({ label, icon, href }) => {
              const active = pathname === href;
              return (
                <li key={href}>
                  <Link
                    href={href}
                    className={`flex items-center gap-3 px-4 py-3 transition-colors duration-200 
                      ${ active
                        ? "text-orange-600 font-semibold border-r-4 border-orange-600 bg-orange-50/50"
                        : "text-slate-500 hover:text-orange-600 hover:bg-slate-50"
                      }`}
                    onClick={() => setMobileOpen(false)}
                  >
                    <span className="material-symbols-outlined"{...(active ? { "data-weight": "fill" } : {})}>
                      {icon}
                    </span>

                    <span className="text-[14px] font-semibold leading-5 tracking-[0.02em]">
                      {label}
                    </span>

                  </Link>
                </li>
              );
            }) }
          </ul>
        </div>

        {/* Export Button */}
        <div className="px-6 mt-6">
          <button className="w-full py-2.5 bg-primary-container text-white text-[14px] font-semibold leading-5 tracking-[0.02em] rounded-full hover:bg-primary transition-colors shadow-sm">
            Export Reports
          </button>
        </div>

        {/* Bottom Nav */}
        <div className="mt-8 border-t border-slate-200 pt-4">
          <ul className="space-y-1">
            {bottomNavItems.map(({ label, icon, href }) => (
              <li key={href}>
                <Link
                  href={href}
                  className="flex items-center gap-3 px-4 py-3 text-slate-500 hover:text-orange-600 hover:bg-slate-50 transition-colors duration-200"
                  onClick={() => setMobileOpen(false)}
                >
                  <span className="material-symbols-outlined">{icon}</span>
                  <span className="text-[14px] font-semibold leading-5 tracking-[0.02em]">
                    {label}
                  </span>
                </Link>
              </li>
            ))}
          </ul>

          {/* Logout */}
          <form >
            <button
              type="submit"
              className="w-full flex items-center gap-3 px-4 py-3 text-slate-500 hover:text-red-600 hover:bg-slate-50 transition-colors duration-200"
            >
              <span className="material-symbols-outlined">logout</span>
              <span className="text-[14px] font-semibold leading-5 tracking-[0.02em]">
                Logout
              </span>
            </button>
          </form>
        </div>
      </nav>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div
          className="fixed inset-0 bg-black/30 z-30 md:hidden"
          onClick={() => setMobileOpen(false)}
        />
      )}

      {/* Top App Bar */}
      <header className="bg-white/80 backdrop-blur-md font-['Plus_Jakarta_Sans'] text-sm font-medium fixed top-0 right-0 w-full md:w-[calc(100%-16rem)] z-30 border-b border-slate-200 shadow-sm flex justify-between items-center px-4 md:px-8 h-16">
        {/* Mobile menu button */}
        <button
          className="md:hidden p-2 text-slate-500 hover:bg-slate-100 rounded-full"
          onClick={() => setMobileOpen((prev) => !prev)}
          aria-label="Open menu"
        >
          <span className="material-symbols-outlined">menu</span>
        </button>

        <div className="hidden md:block">
          <h2 className="text-[20px] font-semibold leading-7 text-[#1e1b18]">Overview</h2>
        </div>

        <div className="flex items-center gap-2 md:gap-4">
          {/* Search */}
          <div className="relative hidden sm:block">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">
              search
            </span>
            <input
              type="text"
              placeholder="Search orders, riders..."
              className="pl-10 pr-4 py-2 bg-surface-container rounded-full border-none focus:ring-2 focus:ring-primary-container text-sm w-64 text-on-surface placeholder:text-on-surface-variant/70 outline-none"
            />
          </div>

          {/* Notifications */}
          <button className="text-slate-500 hover:bg-slate-100 rounded-full p-2 relative">
            <span className="material-symbols-outlined">notifications</span>
            <span className="absolute top-2 right-2 w-2 h-2 bg-[#ba1a1a] rounded-full" />
          </button>

          {/* Dark mode toggle (placeholder) */}
          <button className="text-slate-500 hover:bg-slate-100 rounded-full p-2 hidden sm:block">
            <span className="material-symbols-outlined">dark_mode</span>
          </button>

          {/* Account */}
          <button className="text-slate-500 hover:bg-slate-100 rounded-full p-2">
            <span className="material-symbols-outlined" data-weight="fill">
              account_circle
            </span>
          </button>
        </div>
      </header>
    </>
  );
}
