import Navbar from "../component/navbar";

const riders = [
  {
    name: "Marcus Johnson",
    initials: null,
    vehicle: "E-Bike",
    vehicleIcon: "directions_bike",
    status: "Available" as const,
    rating: 4.9,
    runs: "1,204",
    src: "https://lh3.googleusercontent.com/aida-public/AB6AXuB2ed1OtTA1IRgRFzLuvmOEliAWS1tOlQu03Tu7dfQNZcZbk7a5s7XT6DEmTKvLfITUWZxF2tSPkVQQjmoxYgiT23pQ5wOr5UVGEnSb4fI7GwsC_eGDzOFdClsK6w5N3c5PbvvvEGQqVGPXSnS9VPT66tHCd-o0ykbAhztHqVHQmz2OO2mJ7T8eMCl20po7Pmf_HsFWXwdQWZWiYNep2yxCJaFo8ITZkPNeX55eRosHpat-e2Taqt__uwkzuW0UbOccSYveCRQ2tbQ",
  },
  {
    name: "Sarah Chen",
    initials: null,
    vehicle: "Car",
    vehicleIcon: "directions_car",
    status: "Busy" as const,
    rating: 4.8,
    runs: "856",
    src: "https://lh3.googleusercontent.com/aida-public/AB6AXuB753443rvibEmP2jHyTuSTDVk59t7XTP3jyKAaUdNCGSAHdhYnh6nRRNq9Agg6RaHrv1h53bSa2Bi4dQOWeoLrlN7-n36SR5zoHs7DhgbYX3aoNkDxB23uOqiqhTsivnpmlY6OBvQelDyff7HTZy-lADkVehQs690I2zn5DPHa-4hncwb7PD1fB5EKK5yAvsXGP4Vpee08q2YqCDQ-wkO2-Lqe8BbViPy9AP8safA9oWQQumPc4tDWkBHzOePboBHzcEFZB03Krdc",
  },
  {
    name: "David Jones",
    initials: "DJ",
    vehicle: "Bike",
    vehicleIcon: "pedal_bike",
    status: "Offline" as const,
    rating: 4.5,
    runs: "420",
    src: null,
  },
  {
    name: "Alex Rivera",
    initials: null,
    vehicle: "Scooter",
    vehicleIcon: "two_wheeler",
    status: "Pending" as const,
    rating: null,
    runs: "0",
    src: "https://lh3.googleusercontent.com/aida-public/AB6AXuCs2A0HN-_YSFudB2oPzNyAlAZ4_9oF8ri9X8_txhmuuZHXl-7tLx1zSDPCIMt5fsrXpCoJajc8VBqrcLjdJoe9s9G5nqRkZtSEArhseLgYZpu5osEsAyLeleA-2nOk2UsZWv3dNAbAN3os00LIs0Tra0XYY1tAjkZyfYsfC_X-0lK8dcAK5ix9QJmB_PTWMBpupg6u-lxcoZeP6NMzFYGCmRIrRWUwOl12qRn4KDkq-Lnx8DYMHSWSI3Uitno0Wc9MTFuBdjRaWFc",
  },
];

const statusBadge = {
  Available: "bg-[#dcfce7] text-[#166534]",
  Busy: "bg-primary-container/20 text-primary",
  Offline: "bg-surface-variant text-on-surface-variant",
  Pending: "bg-[#fef3c7] text-[#b45309]",
} as const;

const statusDot: Record<string, string> = {
  Available: "bg-[#166534]",
  Busy: "bg-primary",
  Offline: "bg-outline",
};

export default function Fleet() {
  return (
    <>
      <Navbar />

      <main className="md:ml-64 pt-20 pb-8 px-4 sm:px-6 lg:px-8 min-h-screen">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
          <div>
            <h2 className="text-headline-lg text-on-surface">Fleet Management</h2>
            <p className="text-body-sm text-on-surface-variant mt-1">Monitor and manage your delivery network in real-time.</p>
          </div>
          <div className="flex items-center gap-3 w-full sm:w-auto">
            <button className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-surface-container-highest border border-outline-variant text-on-surface text-label-lg rounded-full hover:bg-surface-container transition-colors shadow-sm">
              <span className="material-symbols-outlined text-sm">download</span>
              Export Data
            </button>
            <button className="flex-1 sm:flex-none flex items-center justify-center gap-2 px-4 py-2 bg-primary text-on-primary text-label-lg rounded-full hover:opacity-90 transition-colors shadow-sm">
              <span className="material-symbols-outlined text-sm">add</span>
              Add Rider
            </button>
          </div>
        </div>

        {/* KPI Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-tertiary-container/10 rounded-full blur-xl group-hover:bg-tertiary-container/20 transition-colors"></div>
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-tertiary-container/20 rounded-lg text-tertiary">
                <span className="material-symbols-outlined">group</span>
              </div>
              <span className="flex items-center gap-1 text-tertiary text-label-sm bg-tertiary-container/10 px-2 py-1 rounded-full">
                <span className="material-symbols-outlined text-[12px]">trending_up</span>+2.4%
              </span>
            </div>
            <div className="relative z-10">
              <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1">Total Riders</p>
              <h3 className="text-headline-xl text-on-surface">1,240</h3>
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-[#4ade80]/10 rounded-full blur-xl group-hover:bg-[#4ade80]/20 transition-colors"></div>
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-[#4ade80]/20 rounded-lg text-[#166534]">
                <span className="material-symbols-outlined">two_wheeler</span>
              </div>
              <span className="flex items-center gap-1 text-[#166534] text-label-sm bg-[#4ade80]/10 px-2 py-1 rounded-full">
                <span className="material-symbols-outlined text-[12px]">trending_up</span>+12%
              </span>
            </div>
            <div className="relative z-10">
              <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1">Active Now</p>
              <h3 className="text-headline-xl text-on-surface">850</h3>
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-primary-container/10 rounded-full blur-xl group-hover:bg-primary-container/20 transition-colors"></div>
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-primary-container/20 rounded-lg text-primary">
                <span className="material-symbols-outlined">local_shipping</span>
              </div>
              <span className="text-label-sm text-on-surface-variant">Peak Hours</span>
            </div>
            <div className="relative z-10">
              <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1">On Delivery</p>
              <h3 className="text-headline-xl text-on-surface">420</h3>
            </div>
          </div>

          <div className="bg-surface-container-lowest p-6 rounded-xl border border-surface-variant shadow-sm hover:shadow-md transition-shadow relative overflow-hidden group">
            <div className="absolute -right-4 -top-4 w-24 h-24 bg-[#fbbf24]/10 rounded-full blur-xl group-hover:bg-[#fbbf24]/20 transition-colors"></div>
            <div className="flex justify-between items-start mb-4 relative z-10">
              <div className="p-2 bg-[#fef3c7] rounded-lg text-[#b45309]">
                <span className="material-symbols-outlined">pending_actions</span>
              </div>
              <span className="text-label-sm text-[#b45309] bg-[#fef3c7] px-2 py-1 rounded-full">Requires Action</span>
            </div>
            <div className="relative z-10">
              <p className="text-label-md text-on-surface-variant uppercase tracking-wider mb-1">Pending Verification</p>
              <h3 className="text-headline-xl text-on-surface">15</h3>
            </div>
          </div>
        </div>

        {/* Map + Rider List */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          {/* Map */}
          <div className="xl:col-span-2 bg-surface-container-lowest rounded-xl border border-surface-variant shadow-sm overflow-hidden flex flex-col h-150">
            <div className="p-4 border-b border-surface-variant flex justify-between items-center">
              <h3 className="text-headline-sm text-on-surface">Live Fleet Map</h3>
              <div className="flex gap-2">
                <span className="flex items-center gap-1 text-label-sm text-on-surface-variant bg-surface-container px-2 py-1 rounded-full">
                  <span className="w-2 h-2 rounded-full bg-[#4ade80]"></span> Available
                </span>
                <span className="flex items-center gap-1 text-label-sm text-on-surface-variant bg-surface-container px-2 py-1 rounded-full">
                  <span className="w-2 h-2 rounded-full bg-primary"></span> Busy
                </span>
                <span className="flex items-center gap-1 text-label-sm text-on-surface-variant bg-surface-container px-2 py-1 rounded-full">
                  <span className="w-2 h-2 rounded-full bg-surface-variant"></span> Offline
                </span>
              </div>
            </div>
            <div className="flex-1 relative bg-surface-container">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                alt="City Map"
                className="w-full h-full object-cover opacity-80"
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuA8CecOhvj8Tz3MU3p_bfXDfNv4IoyN0kVnIQo0kVFIYkot1EUHY4EvVE1zKxHepqRcl9k14NCEjAOyfQqM7EdwfVNtHbRdQchUPAbOT6r8BPsLNse1JTrF6dcPFH-9rNMTlYvtDfjnlFiDnmCAbdsxQwQOr2Nvo42gy_CHDQv4DPemPOW55RVOVBpQmKdku8B5mRoOxefFV_4HMHDg5oMOHCiJUwMFMqWYrprRxO9MACccHAq9L7mHArbMFtUb7k5v8lvUzA7zaNA"
              />
              {/* Map Markers */}
              <div className="absolute top-[30%] left-[40%] w-4 h-4 bg-[#4ade80] rounded-full border-2 border-white shadow-md animate-pulse"></div>
              <div className="absolute top-[45%] left-[60%] w-4 h-4 bg-primary rounded-full border-2 border-white shadow-md"></div>
              <div className="absolute top-[60%] left-[35%] w-4 h-4 bg-surface-variant rounded-full border-2 border-white shadow-md"></div>
              <div className="absolute top-[25%] left-[70%] w-4 h-4 bg-[#4ade80] rounded-full border-2 border-white shadow-md"></div>
              {/* Zoom Controls */}
              <div className="absolute bottom-4 right-4 flex flex-col gap-2">
                <button className="w-10 h-10 bg-surface-container-lowest text-on-surface rounded-lg shadow-md border border-surface-variant flex items-center justify-center hover:bg-surface-container transition-colors">
                  <span className="material-symbols-outlined">add</span>
                </button>
                <button className="w-10 h-10 bg-surface-container-lowest text-on-surface rounded-lg shadow-md border border-surface-variant flex items-center justify-center hover:bg-surface-container transition-colors">
                  <span className="material-symbols-outlined">remove</span>
                </button>
                <button className="w-10 h-10 bg-surface-container-lowest text-on-surface rounded-lg shadow-md border border-surface-variant flex items-center justify-center hover:bg-surface-container transition-colors mt-2">
                  <span className="material-symbols-outlined">my_location</span>
                </button>
              </div>
            </div>
          </div>

          {/* Fleet Directory */}
          <div className="bg-surface-container-lowest rounded-xl border border-surface-variant shadow-sm flex flex-col h-150">
            <div className="p-4 border-b border-surface-variant space-y-4">
              <div className="flex justify-between items-center">
                <h3 className="text-headline-sm text-on-surface">Fleet Directory</h3>
                <button className="text-on-surface-variant hover:text-primary transition-colors">
                  <span className="material-symbols-outlined">filter_list</span>
                </button>
              </div>
              <div className="flex gap-2 overflow-x-auto pb-2">
                <button className="px-3 py-1.5 bg-primary-container text-on-primary text-label-sm rounded-full whitespace-nowrap shadow-sm">All Status</button>
                <button className="px-3 py-1.5 bg-surface-container border border-outline-variant text-on-surface text-label-sm rounded-full whitespace-nowrap hover:border-primary transition-colors">Active</button>
                <button className="px-3 py-1.5 bg-surface-container border border-outline-variant text-on-surface text-label-sm rounded-full whitespace-nowrap hover:border-primary transition-colors">Inactive</button>
                <button className="px-3 py-1.5 bg-surface-container border border-outline-variant text-on-surface text-label-sm rounded-full whitespace-nowrap hover:border-primary transition-colors">Pending</button>
                <div className="w-px h-6 bg-surface-variant mx-1 self-center"></div>
                <select className="px-3 py-1.5 bg-surface-container border border-outline-variant text-on-surface text-label-sm rounded-full whitespace-nowrap hover:border-primary transition-colors focus:ring-0 appearance-none">
                  <option>All Zones</option>
                  <option>Downtown</option>
                  <option>Uptown</option>
                </select>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto">
              <table className="w-full text-left border-collapse">
                <thead className="sticky top-0 bg-surface-container-lowest z-10 border-b border-surface-variant shadow-sm">
                  <tr>
                    <th className="py-3 px-4 text-label-md text-on-surface-variant uppercase tracking-wider">Rider</th>
                    <th className="py-3 px-4 text-label-md text-on-surface-variant uppercase tracking-wider">Status</th>
                    <th className="py-3 px-4 text-label-md text-on-surface-variant uppercase tracking-wider text-right">Metrics</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-variant">
                  {riders.map((r) => (
                    <tr key={r.name} className="hover:bg-surface-container/50 transition-colors cursor-pointer">
                      <td className="py-3 px-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-surface-variant flex items-center justify-center text-on-surface font-bold overflow-hidden shrink-0">
                            {r.src ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img alt={r.name} className="w-full h-full object-cover" src={r.src} />
                            ) : (
                              <span>{r.initials}</span>
                            )}
                          </div>
                          <div>
                            <p className="text-label-lg text-on-surface">{r.name}</p>
                            <p className="text-label-sm text-on-surface-variant flex items-center gap-1">
                              <span className="material-symbols-outlined text-[14px]">{r.vehicleIcon}</span>
                              {r.vehicle}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${statusBadge[r.status]}`}>
                          {r.status === "Pending" ? (
                            <span className="material-symbols-outlined text-[12px]">schedule</span>
                          ) : (
                            <span className={`w-1.5 h-1.5 rounded-full ${statusDot[r.status] ?? ""}`}></span>
                          )}
                          {r.status}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-right">
                        <div className="flex flex-col items-end">
                          {r.rating !== null ? (
                            <div className="flex items-center text-[#f59e0b] text-sm">
                              <span className="material-symbols-outlined text-[14px]" data-weight="fill">star</span>
                              <span className="text-label-lg text-on-surface ml-1">{r.rating}</span>
                            </div>
                          ) : (
                            <span className="text-label-sm text-on-surface-variant italic">New Rider</span>
                          )}
                          <span className="text-label-sm text-on-surface-variant">{r.runs} runs</span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-3 border-t border-surface-variant text-center">
              <button className="text-primary text-label-lg hover:underline">View All Riders</button>
            </div>
          </div>
        </div>
      </main>
    </>
  );
}
