import Navbar from "../component/navbar";

const Toggle = ({ defaultChecked = false }: { defaultChecked?: boolean }) => (
  <label className="relative inline-flex items-center cursor-pointer">
    <input defaultChecked={defaultChecked} className="sr-only peer" type="checkbox" />
    <div className="w-11 h-6 bg-surface-variant rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:left-0.5 after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary"></div>
  </label>
);

const admins = [
  { initials: "SJ", name: "Sarah Jenkins", email: "sarah@zestandsavory.com", role: "Super Admin", roleStyle: "bg-primary-container/20 text-primary-fixed-dim", active: true },
  { initials: "MR", name: "Marcus Reed", email: "marcus.r@zestandsavory.com", role: "Manager", roleStyle: "bg-surface-container-high text-on-surface-variant", active: true },
  { initials: "EL", name: "Emma Lin", email: "emma@zestandsavory.com", role: "Editor", roleStyle: "bg-surface-container-high text-on-surface-variant", active: false },
];

export default function Settings() {
  return (
    <>
      <Navbar />

      <main className="pt-16 md:pl-64 min-h-screen pb-20">
        <div className="p-6 md:p-8 max-w-7xl mx-auto space-y-6">
          {/* Page Header */}
          <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
            <div>
              <h2 className="text-headline-lg text-on-surface mb-2">System Settings</h2>
              <p className="text-body-md text-on-surface-variant">Manage platform configurations, security policies, and administrative access.</p>
            </div>
            <div className="flex gap-3">
              <button className="px-6 py-2.5 rounded-full border-2 border-primary text-primary text-label-lg font-bold hover:bg-primary-container hover:text-on-primary-container transition-colors">
                Discard Changes
              </button>
              <button className="px-6 py-2.5 rounded-full bg-primary-container text-on-primary-container text-label-lg font-bold shadow-[0_4px_12px_rgba(255,107,53,0.25)] hover:shadow-[0_6px_16px_rgba(255,107,53,0.35)] transition-shadow">
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
                <div className="absolute top-0 left-0 w-full h-1 bg-linear-to-r from-primary-container to-tertiary-container opacity-50"></div>
                <div className="flex items-center gap-3 mb-6">
                  <div className="w-10 h-10 rounded-full bg-surface-container-low flex items-center justify-center text-primary">
                    <span className="material-symbols-outlined">tune</span>
                  </div>
                  <h3 className="text-headline-sm text-on-surface">General Settings</h3>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Platform Name</label>
                    <input className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all" type="text" defaultValue="Zest & Savory" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Support Email</label>
                    <input className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all" type="email" defaultValue="support@zestandsavory.com" />
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">Default Currency</label>
                    <div className="relative">
                      <select className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none appearance-none">
                        <option value="USD">USD ($)</option>
                        <option value="EUR">EUR (€)</option>
                        <option value="GBP">GBP (£)</option>
                      </select>
                      <span className="material-symbols-outlined absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-on-surface-variant">expand_more</span>
                    </div>
                  </div>
                  <div className="space-y-2">
                    <label className="text-label-md text-on-surface-variant block">System Language</label>
                    <div className="relative">
                      <select className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none appearance-none">
                        <option value="en">English (US)</option>
                        <option value="es">Spanish</option>
                        <option value="fr">French</option>
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
                      <span className="text-primary font-bold">12.5 km</span>
                    </label>
                    <input className="w-full h-2 bg-surface-container-highest rounded-lg appearance-none cursor-pointer accent-primary" max="50" min="1" step="0.5" type="range" defaultValue="12.5" />
                    <div className="flex justify-between text-label-sm text-on-surface-variant mt-1">
                      <span>1km</span><span>50km</span>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4 border-t border-outline-variant/30">
                    <div className="space-y-2">
                      <label className="text-label-md text-on-surface-variant block">Base Service Fee</label>
                      <div className="relative">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-on-surface-variant font-bold">$</span>
                        <input className="w-full bg-surface-container pl-8 pr-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all" step="0.01" type="number" defaultValue="2.99" />
                      </div>
                    </div>
                    <div className="space-y-2">
                      <label className="text-label-md text-on-surface-variant block">Restaurant Commission</label>
                      <div className="relative">
                        <input className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all" step="1" type="number" defaultValue="15" />
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
                    <Toggle defaultChecked />
                  </div>
                  <div className="flex items-center justify-between p-4 bg-surface-container-low rounded-xl">
                    <div>
                      <p className="text-body-md text-on-surface font-semibold">Strict Password Policy</p>
                      <p className="text-label-sm text-on-surface-variant">Min 12 chars, symbols</p>
                    </div>
                    <Toggle defaultChecked />
                  </div>
                  <div className="space-y-2 pt-2">
                    <label className="text-label-md text-on-surface-variant block">Session Timeout (Minutes)</label>
                    <input className="w-full bg-surface-container px-4 py-3 rounded-xl border border-outline-variant/50 focus:border-primary focus:ring-1 focus:ring-primary text-body-md text-on-surface outline-none transition-all" type="number" defaultValue="30" />
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
                    { icon: "mail", label: "System Emails", on: true },
                    { icon: "sms", label: "SMS Notifications", on: true },
                    { icon: "campaign", label: "Marketing Push", on: false },
                  ].map((item, i, arr) => (
                    <div key={item.label} className={`flex items-center justify-between${i < arr.length - 1 ? " border-b border-outline-variant/30 pb-4" : ""}`}>
                      <div className="flex items-center gap-3">
                        <span className="material-symbols-outlined text-on-surface-variant">{item.icon}</span>
                        <span className="text-body-md text-on-surface">{item.label}</span>
                      </div>
                      <Toggle defaultChecked={item.on} />
                    </div>
                  ))}
                </div>
              </section>
            </div>

            {/* Admin Access — full width */}
            <div className="lg:col-span-12">
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
                  <button className="px-5 py-2 rounded-full bg-surface-container-high text-on-surface text-label-lg shadow-sm hover:bg-surface-container-highest transition-colors flex items-center gap-2 border border-outline-variant">
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
                      {admins.map((a, i) => (
                        <tr key={a.email} className={`${i < admins.length - 1 ? "border-b border-outline-variant/10" : ""} hover:bg-surface-container-low/50 transition-colors group`}>
                          <td className="py-4 pl-2">
                            <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-full bg-tertiary-container text-on-tertiary-container flex items-center justify-center font-bold text-label-md">
                                {a.initials}
                              </div>
                              <span className="font-semibold text-on-surface">{a.name}</span>
                            </div>
                          </td>
                          <td className="py-4 text-on-surface-variant">{a.email}</td>
                          <td className="py-4">
                            <span className={`px-3 py-1 rounded-full text-label-md ${a.roleStyle}`}>{a.role}</span>
                          </td>
                          <td className="py-4">
                            {a.active ? (
                              <div className="flex items-center gap-1.5 text-tertiary">
                                <div className="w-2 h-2 rounded-full bg-tertiary"></div>
                                <span className="font-medium">Active</span>
                              </div>
                            ) : (
                              <div className="flex items-center gap-1.5 text-on-surface-variant opacity-70">
                                <div className="w-2 h-2 rounded-full bg-outline"></div>
                                <span className="font-medium">Offline</span>
                              </div>
                            )}
                          </td>
                          <td className="py-4 pr-2 text-right">
                            <button className="text-on-surface-variant hover:text-primary transition-colors opacity-0 group-hover:opacity-100">
                              <span className="material-symbols-outlined">more_vert</span>
                            </button>
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
    </>
  );
}
