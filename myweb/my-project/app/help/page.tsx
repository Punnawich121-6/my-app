import Navbar from "../component/navbar";

const categories = [
  { icon: "rocket_launch", title: "Getting Started", desc: "Basic setup, account configuration, and admin console overview." },
  { icon: "receipt_long", title: "Order Management", desc: "Handling active orders, refunds, cancellations, and customer issues." },
  { icon: "storefront", title: "Restaurant Partners", desc: "Onboarding merchants, menu management, and payout schedules." },
  { icon: "bar_chart", title: "Financial Reporting", desc: "Understanding metrics, tax documentation, and exportable reports." },
];

const faqs = [
  {
    q: "How to verify a new rider?",
    a: "To verify a new rider, navigate to the Fleet tab in the sidebar. Select \"Pending Approvals\" and click on the applicant's profile. You must verify their uploaded ID, vehicle insurance, and background check documents before clicking the \"Approve Rider\" button.",
    open: true,
  },
  { q: "How to process a refund?", a: null, open: false },
  { q: "What is the payout schedule for restaurants?", a: null, open: false },
  { q: "How do I update tax documentation for a region?", a: null, open: false },
];

const resources = [
  { icon: "menu_book", title: "Knowledge Base", desc: "Full documentation" },
  { icon: "code", title: "Developer API", desc: "Integration docs & endpoints" },
  { icon: "forum", title: "Community Forum", desc: "Discuss with other admins", external: true },
];

export default function Help() {
  return (
    <>
      <Navbar />

      <main className="md:ml-64 pt-16 min-h-screen pb-20">
        <div className="p-6 md:p-16 max-w-7xl mx-auto space-y-16">
          {/* Hero Search */}
          <section className="text-center space-y-6 max-w-3xl mx-auto mt-6">
            <h2 className="text-headline-xl text-on-background">How can we help you today?</h2>
            <p className="text-body-lg text-secondary">Search our knowledge base or browse categories below.</p>
            <div className="relative mt-10 group">
              <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-secondary group-focus-within:text-primary transition-colors text-2xl">search</span>
              <input
                className="w-full bg-surface-container-lowest border border-outline-variant rounded-full py-3 pl-16 pr-4 text-body-lg text-on-surface focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent shadow-sm hover:shadow-md transition-shadow"
                placeholder="Search for articles, guides, or keywords..."
                type="text"
              />
              <button className="absolute right-2 top-1/2 -translate-y-1/2 bg-primary-container text-on-primary text-label-md px-6 py-1 rounded-full hover:bg-primary transition-colors">
                Search
              </button>
            </div>
            <div className="flex flex-wrap items-center justify-center gap-3 mt-3">
              <span className="text-label-sm text-secondary uppercase tracking-widest">Popular:</span>
              {["Refunds", "Rider Verification", "API Docs"].map((tag) => (
                <button key={tag} className="text-label-md text-primary bg-primary-fixed/20 px-3 py-1 rounded-full hover:bg-primary hover:text-on-primary transition-colors">
                  {tag}
                </button>
              ))}
            </div>
          </section>

          {/* Help Categories */}
          <section className="space-y-3">
            <h3 className="text-headline-md text-on-surface border-b border-outline-variant pb-2">Help Categories</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {categories.map((c) => (
                <a key={c.title} className="block bg-surface-container-lowest border border-outline-variant rounded-xl p-6 shadow-sm hover:shadow-md hover:border-primary/50 transition-all group" href="#">
                  <div className="w-12 h-12 bg-surface-container rounded-full flex items-center justify-center mb-3 group-hover:bg-primary-fixed/30 transition-colors">
                    <span className="material-symbols-outlined text-primary text-2xl">{c.icon}</span>
                  </div>
                  <h4 className="text-headline-sm text-on-surface mb-1 group-hover:text-primary transition-colors">{c.title}</h4>
                  <p className="text-body-sm text-secondary">{c.desc}</p>
                </a>
              ))}
            </div>
          </section>

          {/* FAQs + Contact */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-16">
            {/* FAQs */}
            <section className="lg:col-span-2 space-y-3">
              <h3 className="text-headline-md text-on-surface border-b border-outline-variant pb-2">Frequently Asked Questions</h3>
              <div className="space-y-3">
                {faqs.map((f) => (
                  <div key={f.q} className="bg-surface-container-lowest border border-outline-variant rounded-xl overflow-hidden shadow-sm">
                    <button className="w-full flex items-center justify-between p-4 text-left hover:bg-surface-container/50 transition-colors">
                      <span className="text-headline-sm text-on-surface">{f.q}</span>
                      <span className={`material-symbols-outlined transition-transform ${f.open ? "text-primary rotate-180" : "text-secondary"}`}>
                        expand_more
                      </span>
                    </button>
                    {f.open && f.a && (
                      <div className="p-4 pt-0 border-t border-outline-variant bg-surface-bright">
                        <p className="text-body-md text-on-surface-variant mt-4">{f.a}</p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </section>

            {/* Contact & Resources */}
            <section className="space-y-16">
              {/* Contact Card */}
              <div className="bg-surface-container-low border border-outline-variant rounded-xl p-6 shadow-sm relative overflow-hidden">
                <div className="absolute -right-4 -top-4 w-24 h-24 bg-primary-fixed/20 rounded-full blur-xl"></div>
                <h3 className="text-headline-md text-on-surface mb-3 relative z-10">Still need help?</h3>
                <p className="text-body-sm text-secondary mb-6 relative z-10">Our support team is available 24/7 for urgent administrative issues.</p>
                <div className="space-y-2 relative z-10">
                  <button className="w-full flex items-center justify-between bg-primary-container text-on-primary text-label-md py-3 px-6 rounded-full shadow-md shadow-primary/20 hover:bg-primary transition-colors">
                    <span className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-sm">chat_bubble</span> Live Chat
                    </span>
                    <span className="bg-white/20 px-2 py-0.5 rounded-full text-xs">Wait: ~2m</span>
                  </button>
                  <button className="w-full flex items-center justify-center gap-2 bg-surface-container-lowest border border-outline text-on-surface text-label-md py-3 px-6 rounded-full hover:bg-surface-container transition-colors">
                    <span className="material-symbols-outlined text-sm">mail</span> Email Support
                  </button>
                </div>
              </div>

              {/* Resources */}
              <div className="bg-surface-container-lowest border border-outline-variant rounded-xl p-6 shadow-sm">
                <h3 className="text-headline-sm text-on-surface mb-3">Resources</h3>
                <ul className="divide-y divide-outline-variant">
                  {resources.map((r) => (
                    <li key={r.title}>
                      <a className="flex items-center justify-between py-4 group" href="#">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-secondary-container flex items-center justify-center group-hover:bg-primary-container transition-colors">
                            <span className="material-symbols-outlined text-on-secondary-container group-hover:text-on-primary text-sm">{r.icon}</span>
                          </div>
                          <div>
                            <p className="text-label-lg text-on-surface group-hover:text-primary transition-colors">{r.title}</p>
                            <p className="text-body-sm text-secondary text-xs">{r.desc}</p>
                          </div>
                        </div>
                        <span className="material-symbols-outlined text-secondary group-hover:text-primary">
                          {r.external ? "open_in_new" : "chevron_right"}
                        </span>
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            </section>
          </div>
        </div>
      </main>
    </>
  );
}
