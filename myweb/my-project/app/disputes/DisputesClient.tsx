"use client";

import { useState, useEffect, useCallback } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────
type Dispute = {
  id: number;
  order_number: string;
  customer_name: string;
  restaurant_name: string;
  rider_name: string | null;
  reason_type: string;
  status: string;
  confidence_score: number | null;
  ai_verdict: string | null;
  ai_fault_party: string | null;
  refund_type: string;
  refund_amount: number;
  created_at: string;
  resolved_at: string | null;
};

type DisputeDetail = Dispute & {
  description: string;
  evidence_urls: string;
  ai_reasoning: string | null;
  admin_override_verdict: string | null;
  admin_override_notes: string | null;
  resolved_by: string | null;
  actions: { id: number; action_type: string; actor_role: string; notes: string; created_at: string }[];
};

type Stats = {
  total: number;
  auto_resolved: number;
  pending_review: number;
  escalated: number;
  admin_resolved: number;
  analyzing: number;
  total_refunded: number;
  avg_confidence: number | null;
};

// ── Helpers ───────────────────────────────────────────────────────────────────
const STATUS_FILTERS = [
  { value: "all",            label: "ทั้งหมด" },
  { value: "analyzing",      label: "กำลังวิเคราะห์" },
  { value: "pending_review", label: "รอ Admin" },
  { value: "escalated",      label: "Escalated" },
  { value: "auto_resolved",  label: "AI แก้แล้ว" },
  { value: "admin_resolved", label: "Admin แก้แล้ว" },
];

const REASON_LABELS: Record<string, string> = {
  not_received:  "ไม่ได้รับอาหาร",
  wrong_item:    "ได้รับผิดรายการ",
  late_delivery: "อาหารช้ามาก",
  quality_issue: "คุณภาพไม่ตรงมาตรฐาน",
  overcharged:   "ถูกเรียกเก็บผิด",
  other:         "อื่นๆ",
};

const VERDICT_LABELS: Record<string, string> = {
  customer_wins: "ลูกค้าชนะ",
  merchant_wins: "ร้านชนะ",
  rider_wins:    "ไรเดอร์ชนะ",
  shared_fault:  "ผิดร่วมกัน",
  inconclusive:  "ไม่สรุปได้",
};

const FAULT_LABELS: Record<string, string> = {
  customer: "ลูกค้า",
  merchant: "ร้านอาหาร",
  rider:    "ไรเดอร์",
  shared:   "หลายฝ่าย",
  none:     "ไม่ระบุ",
};

function statusBadge(status: string) {
  const map: Record<string, string> = {
    analyzing:      "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
    auto_resolved:  "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300",
    pending_review: "bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-300",
    escalated:      "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
    admin_resolved: "bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300",
    closed:         "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400",
  };
  const labels: Record<string, string> = {
    analyzing:      "กำลังวิเคราะห์",
    auto_resolved:  "AI แก้แล้ว",
    pending_review: "รอ Admin",
    escalated:      "Escalated",
    admin_resolved: "Admin แก้แล้ว",
    closed:         "ปิดแล้ว",
  };
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold ${map[status] || map.closed}`}>
      {status === "analyzing" && <span className="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse" />}
      {labels[status] || status}
    </span>
  );
}

function confidenceBadge(score: number | null) {
  if (score === null) return <span className="text-on-surface-variant text-xs">—</span>;
  const color = score >= 80 ? "text-green-600 dark:text-green-400"
    : score >= 60 ? "text-yellow-600 dark:text-yellow-400"
    : "text-red-600 dark:text-red-400";
  const ring = score >= 80 ? "border-green-500" : score >= 60 ? "border-yellow-500" : "border-red-500";
  return (
    <span className={`inline-flex items-center gap-1 text-xs font-bold ${color}`}>
      <span className={`w-6 h-6 rounded-full border-2 ${ring} flex items-center justify-center text-[10px]`}>
        {Math.round(score)}
      </span>
      %
    </span>
  );
}

function fmtDate(d: string | null) {
  if (!d) return "—";
  return new Date(d).toLocaleDateString("th-TH", { day: "2-digit", month: "short", year: "2-digit", hour: "2-digit", minute: "2-digit" });
}

function fmtMoney(n: number) {
  return `฿${Number(n).toLocaleString("th-TH", { minimumFractionDigits: 2 })}`;
}

// ── Main Component ─────────────────────────────────────────────────────────────
export default function DisputesClient() {
  const [disputes, setDisputes]   = useState<Dispute[]>([]);
  const [stats, setStats]         = useState<Stats | null>(null);
  const [activeFilter, setFilter] = useState("all");
  const [loading, setLoading]     = useState(true);
  const [total, setTotal]         = useState(0);
  const [page, setPage]           = useState(1);
  const PAGE_SIZE = 20;

  // Detail modal
  const [detail, setDetail]     = useState<DisputeDetail | null>(null);
  const [detailLoading, setDL]  = useState(false);
  const [overrideMode, setOM]   = useState(false);
  const [overrideForm, setOF]   = useState({ verdict: "", notes: "", refundType: "none", refundAmount: "" });
  const [submitting, setSub]    = useState(false);

  const fetchDisputes = useCallback(async (filter: string, pg: number) => {
    setLoading(true);
    try {
      const res  = await fetch(`/api/disputes?status=${filter}&page=${pg}&limit=${PAGE_SIZE}`);
      const data = await res.json();
      setDisputes(data.disputes || []);
      setTotal(data.total || 0);
      setStats(data.stats || null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchDisputes(activeFilter, page); }, [activeFilter, page, fetchDisputes]);

  // Poll every 10s for analyzing disputes
  useEffect(() => {
    const hasAnalyzing = disputes.some(d => d.status === "analyzing");
    if (!hasAnalyzing) return;
    const t = setInterval(() => fetchDisputes(activeFilter, page), 10_000);
    return () => clearInterval(t);
  }, [disputes, activeFilter, page, fetchDisputes]);

  async function openDetail(id: number) {
    setDL(true); setDetail(null); setOM(false);
    const res  = await fetch(`/api/disputes/${id}`);
    const data = await res.json();
    setDetail(data);
    setDL(false);
  }

  async function submitOverride() {
    if (!detail || !overrideForm.verdict) return;
    setSub(true);
    await fetch(`/api/disputes/${detail.id}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        verdict:     overrideForm.verdict,
        notes:       overrideForm.notes,
        refundType:  overrideForm.refundType,
        refundAmount: Number(overrideForm.refundAmount || 0),
      }),
    });
    setSub(false);
    setDetail(null);
    fetchDisputes(activeFilter, page);
  }

  // ── Render ──────────────────────────────────────────────────────────────────
  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <div className="space-y-6">

      {/* ── Stats Cards ── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: "ทั้งหมด",       value: stats?.total         ?? "—", icon: "gavel",             color: "text-primary-container" },
          { label: "AI แก้แล้ว",    value: stats?.auto_resolved  ?? "—", icon: "smart_toy",         color: "text-green-600 dark:text-green-400" },
          { label: "รอ Admin",       value: stats?.pending_review ?? "—", icon: "pending_actions",   color: "text-yellow-600 dark:text-yellow-400" },
          { label: "Escalated",      value: stats?.escalated      ?? "—", icon: "priority_high",     color: "text-red-600 dark:text-red-400" },
        ].map(({ label, value, icon, color }) => (
          <div key={label} className="bg-surface-container-lowest rounded-xl border border-surface-container-highest p-5 shadow-sm flex flex-col justify-between gap-2">
            <div className="flex items-center justify-between">
              <span className="text-label-md text-on-surface-variant uppercase tracking-wider">{label}</span>
              <span className={`material-symbols-outlined ${color} p-1.5 bg-surface-container-low rounded-lg`}>{icon}</span>
            </div>
            <span className="text-headline-xl text-on-background font-bold">{value}</span>
          </div>
        ))}
      </div>

      {/* extra stat row */}
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest p-4 shadow-sm">
          <p className="text-label-sm text-on-surface-variant mb-1">รวมเงินคืน</p>
          <p className="text-title-lg text-on-background font-bold">{stats ? fmtMoney(stats.total_refunded) : "—"}</p>
        </div>
        <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest p-4 shadow-sm">
          <p className="text-label-sm text-on-surface-variant mb-1">Avg. AI Confidence</p>
          <p className="text-title-lg text-on-background font-bold">{stats?.avg_confidence != null ? `${stats.avg_confidence}%` : "—"}</p>
        </div>
        <div className="bg-surface-container-lowest rounded-xl border border-surface-container-highest p-4 shadow-sm">
          <p className="text-label-sm text-on-surface-variant mb-1">Admin ตัดสินเอง</p>
          <p className="text-title-lg text-on-background font-bold">{stats?.admin_resolved ?? "—"}</p>
        </div>
      </div>

      {/* ── Table Card ── */}
      <div className="bg-surface-container-lowest rounded-3xl border border-surface-container-highest shadow-sm overflow-hidden">

        {/* Filter tabs */}
        <div className="flex gap-1 p-4 border-b border-surface-container-highest overflow-x-auto">
          {STATUS_FILTERS.map(f => (
            <button
              key={f.value}
              onClick={() => { setFilter(f.value); setPage(1); }}
              className={`px-3 py-1.5 rounded-full text-sm font-semibold whitespace-nowrap transition-colors ${
                activeFilter === f.value
                  ? "bg-primary-container text-on-primary"
                  : "text-on-surface-variant hover:bg-surface-container"
              }`}
            >
              {f.label}
            </button>
          ))}
          <button
            onClick={() => fetchDisputes(activeFilter, page)}
            className="ml-auto p-1.5 rounded-full text-on-surface-variant hover:bg-surface-container"
            title="รีเฟรช"
          >
            <span className="material-symbols-outlined text-[18px]">refresh</span>
          </button>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[900px]">
            <thead>
              <tr className="bg-surface-container text-on-surface-variant text-label-md uppercase tracking-wider border-b border-surface-container-highest">
                <th className="p-4 font-semibold">#</th>
                <th className="p-4 font-semibold">ออเดอร์</th>
                <th className="p-4 font-semibold">ลูกค้า / ร้าน</th>
                <th className="p-4 font-semibold">ประเภทปัญหา</th>
                <th className="p-4 font-semibold">Confidence</th>
                <th className="p-4 font-semibold">AI ตัดสิน</th>
                <th className="p-4 font-semibold">สถานะ</th>
                <th className="p-4 font-semibold">คืนเงิน</th>
                <th className="p-4 font-semibold">วันที่</th>
                <th className="p-4 font-semibold text-center">จัดการ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-container-highest">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="animate-pulse">
                    {Array.from({ length: 10 }).map((__, j) => (
                      <td key={j} className="p-4"><div className="h-4 bg-surface-container rounded w-full" /></td>
                    ))}
                  </tr>
                ))
              ) : disputes.length === 0 ? (
                <tr>
                  <td colSpan={10} className="p-12 text-center text-on-surface-variant">
                    <span className="material-symbols-outlined text-4xl block mb-2 opacity-40">gavel</span>
                    ยังไม่มี dispute ในขณะนี้
                  </td>
                </tr>
              ) : disputes.map(d => (
                <tr key={d.id} className="hover:bg-surface-container/50 transition-colors">
                  <td className="p-4 text-on-surface-variant text-sm">#{d.id}</td>
                  <td className="p-4 text-sm font-mono text-on-background">{d.order_number || `#${d.id}`}</td>
                  <td className="p-4">
                    <p className="text-sm font-semibold text-on-background">{d.customer_name || "—"}</p>
                    <p className="text-xs text-on-surface-variant">{d.restaurant_name || "—"}</p>
                  </td>
                  <td className="p-4 text-sm text-on-background">{REASON_LABELS[d.reason_type] || d.reason_type}</td>
                  <td className="p-4">{confidenceBadge(d.confidence_score)}</td>
                  <td className="p-4 text-xs text-on-surface-variant">{d.ai_verdict ? VERDICT_LABELS[d.ai_verdict] || d.ai_verdict : "—"}</td>
                  <td className="p-4">{statusBadge(d.status)}</td>
                  <td className="p-4 text-sm">
                    {d.refund_type !== "none" ? (
                      <span className="text-green-600 dark:text-green-400 font-semibold">{fmtMoney(d.refund_amount)}</span>
                    ) : <span className="text-on-surface-variant">—</span>}
                  </td>
                  <td className="p-4 text-xs text-on-surface-variant whitespace-nowrap">{fmtDate(d.created_at)}</td>
                  <td className="p-4 text-center">
                    <button
                      onClick={() => openDetail(d.id)}
                      className="p-1.5 text-on-surface-variant hover:text-primary-container hover:bg-surface-container rounded-full transition-colors"
                      title="ดูรายละเอียด"
                    >
                      <span className="material-symbols-outlined text-[18px]">open_in_new</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="p-4 border-t border-surface-container-highest flex items-center justify-between text-body-sm text-on-surface-variant">
            <span>แสดง {(page - 1) * PAGE_SIZE + 1}–{Math.min(page * PAGE_SIZE, total)} จาก {total}</span>
            <div className="flex gap-1 items-center">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1}
                className="p-1 rounded hover:bg-surface-container disabled:opacity-40">
                <span className="material-symbols-outlined text-sm">chevron_left</span>
              </button>
              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map(p => (
                <button key={p} onClick={() => setPage(p)}
                  className={`w-7 h-7 rounded flex items-center justify-center text-sm font-medium ${
                    p === page ? "bg-primary-container text-on-primary" : "hover:bg-surface-container"
                  }`}>{p}</button>
              ))}
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages}
                className="p-1 rounded hover:bg-surface-container disabled:opacity-40">
                <span className="material-symbols-outlined text-sm">chevron_right</span>
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── Detail Modal ── */}
      {(detail || detailLoading) && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4" onClick={() => { setDetail(null); setOM(false); }}>
          <div
            className="bg-surface-container-lowest rounded-3xl w-full max-w-2xl max-h-[90vh] overflow-y-auto shadow-2xl"
            onClick={e => e.stopPropagation()}
          >
            {detailLoading ? (
              <div className="p-12 text-center text-on-surface-variant">
                <span className="material-symbols-outlined text-4xl animate-spin block mb-2">progress_activity</span>
                กำลังโหลด...
              </div>
            ) : detail && (
              <>
                {/* Modal header */}
                <div className="flex items-center justify-between p-6 border-b border-surface-container-highest">
                  <div>
                    <h2 className="text-title-lg font-bold text-on-background">Dispute #{detail.id}</h2>
                    <p className="text-body-sm text-on-surface-variant mt-0.5">ออเดอร์ {detail.order_number}</p>
                  </div>
                  <div className="flex items-center gap-2">
                    {statusBadge(detail.status)}
                    <button onClick={() => { setDetail(null); setOM(false); }}
                      className="p-1.5 text-on-surface-variant hover:bg-surface-container rounded-full">
                      <span className="material-symbols-outlined">close</span>
                    </button>
                  </div>
                </div>

                <div className="p-6 space-y-5">

                  {/* Parties */}
                  <div className="grid grid-cols-3 gap-3 text-center">
                    {[
                      { label: "ลูกค้า", name: detail.customer_name, icon: "person", fault: detail.ai_fault_party === "customer" },
                      { label: "ร้านอาหาร", name: detail.restaurant_name, icon: "restaurant", fault: detail.ai_fault_party === "merchant" },
                      { label: "ไรเดอร์", name: detail.rider_name || "ไม่มี", icon: "delivery_dining", fault: detail.ai_fault_party === "rider" },
                    ].map(({ label, name, icon, fault }) => (
                      <div key={label} className={`rounded-2xl p-3 border ${fault ? "border-red-400 bg-red-50 dark:bg-red-900/20" : "border-surface-container-highest bg-surface-container"}`}>
                        <span className={`material-symbols-outlined text-2xl ${fault ? "text-red-600 dark:text-red-400" : "text-on-surface-variant"}`}>{icon}</span>
                        <p className="text-label-sm text-on-surface-variant mt-1">{label}</p>
                        <p className="text-body-sm font-semibold text-on-background truncate">{name || "—"}</p>
                        {fault && <p className="text-[10px] text-red-600 dark:text-red-400 font-bold mt-0.5">ฝ่ายที่ผิด</p>}
                      </div>
                    ))}
                  </div>

                  {/* Problem */}
                  <div className="bg-surface-container rounded-2xl p-4">
                    <p className="text-label-sm text-on-surface-variant mb-1">ประเภทปัญหา</p>
                    <p className="text-body-md font-semibold text-on-background">{REASON_LABELS[detail.reason_type] || detail.reason_type}</p>
                    {detail.description && <p className="text-body-sm text-on-surface-variant mt-1">{detail.description}</p>}
                  </div>

                  {/* Evidence images */}
                  {detail.evidence_urls && (() => {
                    try {
                      const urls: string[] = JSON.parse(detail.evidence_urls);
                      if (urls.length === 0) return null;
                      return (
                        <div>
                          <p className="text-label-sm text-on-surface-variant mb-2">หลักฐานที่แนบมา ({urls.length} รูป)</p>
                          <div className="flex gap-2 flex-wrap">
                            {urls.map((u, i) => (
                              <a key={i} href={`${process.env.NEXT_PUBLIC_BACKEND_URL ?? 'http://localhost:3001'}${u}`} target="_blank" rel="noreferrer">
                                <img src={`${process.env.NEXT_PUBLIC_BACKEND_URL ?? 'http://localhost:3001'}${u}`} alt={`evidence-${i}`}
                                  className="w-20 h-20 object-cover rounded-xl border border-surface-container-highest hover:opacity-80 transition-opacity" />
                              </a>
                            ))}
                          </div>
                        </div>
                      );
                    } catch { return null; }
                  })()}

                  {/* AI Analysis */}
                  {detail.ai_reasoning && (
                    <div className="bg-primary-container/5 border border-primary-container/20 rounded-2xl p-4">
                      <div className="flex items-center gap-2 mb-3">
                        <span className="material-symbols-outlined text-primary-container">smart_toy</span>
                        <p className="text-label-md font-bold text-primary-container">AI Analysis</p>
                        {confidenceBadge(detail.confidence_score)}
                      </div>
                      <div className="grid grid-cols-2 gap-3 mb-3 text-sm">
                        <div>
                          <p className="text-on-surface-variant text-xs">ผลการตัดสิน</p>
                          <p className="font-semibold text-on-background">{detail.ai_verdict ? VERDICT_LABELS[detail.ai_verdict] || detail.ai_verdict : "—"}</p>
                        </div>
                        <div>
                          <p className="text-on-surface-variant text-xs">ฝ่ายที่ผิด</p>
                          <p className="font-semibold text-on-background">{detail.ai_fault_party ? FAULT_LABELS[detail.ai_fault_party] || detail.ai_fault_party : "—"}</p>
                        </div>
                        <div>
                          <p className="text-on-surface-variant text-xs">คืนเงิน</p>
                          <p className="font-semibold text-on-background">
                            {detail.refund_type === "none" ? "ไม่คืน" : `${detail.refund_type === "full" ? "คืนเต็ม" : "คืนบางส่วน"} — ${fmtMoney(detail.refund_amount)}`}
                          </p>
                        </div>
                        <div>
                          <p className="text-on-surface-variant text-xs">แก้โดย</p>
                          <p className="font-semibold text-on-background">{detail.resolved_by || "—"}</p>
                        </div>
                      </div>
                      <p className="text-body-sm text-on-background leading-relaxed">{detail.ai_reasoning}</p>
                    </div>
                  )}

                  {/* Admin override result */}
                  {detail.admin_override_verdict && (
                    <div className="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-700 rounded-2xl p-4">
                      <p className="text-label-sm font-bold text-purple-700 dark:text-purple-300 mb-1">Admin Override</p>
                      <p className="text-body-sm text-on-background">{detail.admin_override_verdict}</p>
                      {detail.admin_override_notes && <p className="text-body-sm text-on-surface-variant mt-1">{detail.admin_override_notes}</p>}
                    </div>
                  )}

                  {/* Action timeline */}
                  {detail.actions?.length > 0 && (
                    <div>
                      <p className="text-label-sm text-on-surface-variant mb-2">Timeline</p>
                      <div className="space-y-2">
                        {detail.actions.map(a => (
                          <div key={a.id} className="flex gap-3 items-start text-sm">
                            <span className="mt-0.5 w-5 h-5 rounded-full bg-surface-container flex items-center justify-center shrink-0">
                              <span className="material-symbols-outlined text-[12px] text-on-surface-variant">
                                {a.actor_role === "AI" ? "smart_toy" : a.actor_role === "admin" ? "admin_panel_settings" : "person"}
                              </span>
                            </span>
                            <div className="flex-1">
                              <p className="text-on-background">{a.notes}</p>
                              <p className="text-xs text-on-surface-variant">{fmtDate(a.created_at)}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Admin Override Form */}
                  {(detail.status === "pending_review" || detail.status === "escalated") && !overrideMode && (
                    <button
                      onClick={() => setOM(true)}
                      className="w-full py-2.5 bg-primary-container text-on-primary rounded-full text-sm font-semibold hover:bg-primary transition-colors flex items-center justify-center gap-2"
                    >
                      <span className="material-symbols-outlined text-[18px]">admin_panel_settings</span>
                      ตัดสิน / Override ด้วยตนเอง
                    </button>
                  )}

                  {overrideMode && (
                    <div className="border border-surface-container-highest rounded-2xl p-4 space-y-3">
                      <p className="text-label-md font-bold text-on-background">Admin Override</p>
                      <div>
                        <label className="text-label-sm text-on-surface-variant block mb-1">ผลการตัดสิน *</label>
                        <input
                          value={overrideForm.verdict}
                          onChange={e => setOF(f => ({ ...f, verdict: e.target.value }))}
                          placeholder="เช่น customer_wins, merchant_wins, inconclusive"
                          className="w-full px-3 py-2 rounded-xl border border-surface-container-highest bg-surface-container text-sm text-on-background focus:outline-none focus:border-primary-container"
                        />
                      </div>
                      <div>
                        <label className="text-label-sm text-on-surface-variant block mb-1">หมายเหตุ</label>
                        <textarea
                          value={overrideForm.notes}
                          onChange={e => setOF(f => ({ ...f, notes: e.target.value }))}
                          rows={2}
                          className="w-full px-3 py-2 rounded-xl border border-surface-container-highest bg-surface-container text-sm text-on-background focus:outline-none focus:border-primary-container resize-none"
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <label className="text-label-sm text-on-surface-variant block mb-1">ประเภทคืนเงิน</label>
                          <select
                            value={overrideForm.refundType}
                            onChange={e => setOF(f => ({ ...f, refundType: e.target.value }))}
                            className="w-full px-3 py-2 rounded-xl border border-surface-container-highest bg-surface-container text-sm text-on-background focus:outline-none"
                          >
                            <option value="none">ไม่คืน</option>
                            <option value="partial">คืนบางส่วน</option>
                            <option value="full">คืนเต็ม</option>
                          </select>
                        </div>
                        <div>
                          <label className="text-label-sm text-on-surface-variant block mb-1">จำนวนเงินคืน (฿)</label>
                          <input
                            type="number" min="0"
                            value={overrideForm.refundAmount}
                            onChange={e => setOF(f => ({ ...f, refundAmount: e.target.value }))}
                            className="w-full px-3 py-2 rounded-xl border border-surface-container-highest bg-surface-container text-sm text-on-background focus:outline-none focus:border-primary-container"
                          />
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button onClick={() => setOM(false)}
                          className="flex-1 py-2 rounded-full border border-surface-container-highest text-sm font-semibold text-on-surface-variant hover:bg-surface-container">
                          ยกเลิก
                        </button>
                        <button onClick={submitOverride} disabled={submitting || !overrideForm.verdict}
                          className="flex-1 py-2 rounded-full bg-primary-container text-on-primary text-sm font-semibold hover:bg-primary transition-colors disabled:opacity-50">
                          {submitting ? "กำลังบันทึก..." : "ยืนยัน Override"}
                        </button>
                      </div>
                    </div>
                  )}

                </div>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
