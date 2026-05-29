"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { useSearchParams } from "next/navigation";
import { mountAdminSocket, unmountAdminSocket } from "@/app/lib/socket";

const API = "/api/support";
const BACKEND = process.env.NEXT_PUBLIC_BACKEND_URL ?? "http://localhost:3001";
const UPLOAD_API = "/api/support";

type Thread = {
  store_id: string;
  store_name: string | null;
  last_message: string | null;
  last_image_url: string | null;
  last_role: "store" | "admin" | null;
  last_at: string | null;
  unread_count: number;
};

type Message = {
  id: number;
  store_id: string;
  store_name: string | null;
  sender_role: "store" | "admin";
  sender_name: string | null;
  message: string;
  image_url: string | null;
  is_read: number;
  created_at: string;
};

function timeAgo(dateStr: string | null) {
  if (!dateStr) return "";
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000);
  if (diff < 60) return "เมื่อกี้";
  if (diff < 3600) return `${Math.floor(diff / 60)} นาทีที่แล้ว`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} ชม. ที่แล้ว`;
  return new Date(dateStr).toLocaleDateString("th-TH", { day: "numeric", month: "short" });
}

function formatTime(dateStr: string) {
  return new Date(dateStr).toLocaleTimeString("th-TH", { hour: "2-digit", minute: "2-digit" });
}

export default function SupportClient() {
  const searchParams = useSearchParams();
  const [threads, setThreads] = useState<Thread[]>([]);
  const [selected, setSelected] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [loadingMsgs, setLoadingMsgs] = useState(false);
  const [search, setSearch] = useState("");
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [aiDrafting, setAiDrafting] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const lastDraftedMsgIdRef = useRef<number | null>(null);

  const fetchThreads = useCallback(async () => {
    try {
      const res = await fetch(`${API}?type=threads`);
      if (res.ok) setThreads(await res.json());
    } catch {}
  }, []);

  // Auto-open thread from notification link (?store=storeId)
  const autoOpenDone = useRef(false);
  useEffect(() => {
    if (autoOpenDone.current || threads.length === 0) return;
    const storeParam = searchParams.get("store");
    if (storeParam) {
      autoOpenDone.current = true;
      selectThread(storeParam);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [threads, searchParams]);

  const fetchMessages = useCallback(async (storeId: string) => {
    try {
      const res = await fetch(`${API}/${storeId}`);
      if (res.ok) {
        const data: Message[] = await res.json();
        setMessages(data);
      }
    } catch {}
  }, []);

  const markRead = useCallback(async (storeId: string) => {
    try {
      await fetch(`${API}/${storeId}`, { method: "PUT" });
      setThreads(prev => prev.map(t => t.store_id === storeId ? { ...t, unread_count: 0 } : t));
    } catch {}
  }, []);

  const autoDraft = useCallback(async (storeId: string, msgs: Message[]) => {
    const lastMsg = msgs[msgs.length - 1];
    if (!lastMsg || lastMsg.sender_role !== "store") return;
    if (lastDraftedMsgIdRef.current === lastMsg.id) return;
    lastDraftedMsgIdRef.current = lastMsg.id;

    setAiDrafting(true);
    setInput("");
    try {
      const res = await fetch(`${API}/${storeId}/ai-draft`, { method: "POST" });
      const data = await res.json();
      if (data.draft) {
        setInput(data.draft);
        setTimeout(() => {
          inputRef.current?.focus();
          inputRef.current?.setSelectionRange(data.draft.length, data.draft.length);
        }, 50);
      }
    } catch {}
    setAiDrafting(false);
  }, []);

  useEffect(() => {
    fetchThreads();
    const id = setInterval(fetchThreads, 5000);

    const socket = mountAdminSocket();
    socket.on('new_support_message', ({ storeId, message }: { storeId: string; message: Message }) => {
      // อัพเดต thread list ทันที
      fetchThreads();

      // ถ้ากำลังเปิด thread นั้นอยู่ → ต่อ message เข้า chat ทันที
      setSelected(prev => {
        if (prev === storeId) {
          setMessages(msgs => {
            if (msgs.find(m => m.id === message.id)) return msgs;
            const updated = [...msgs, message];
            autoDraft(storeId, updated);
            return updated;
          });
        }
        return prev;
      });
    });

    return () => {
      clearInterval(id);
      socket.off('new_support_message');
      unmountAdminSocket();
    };
  }, [fetchThreads, autoDraft]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function selectThread(storeId: string) {
    setSelected(storeId);
    setInput("");
    lastDraftedMsgIdRef.current = null;
    setLoadingMsgs(true);
    const res = await fetch(`${API}/${storeId}`);
    let msgs: Message[] = [];
    if (res.ok) {
      msgs = await res.json();
      setMessages(msgs);
    }
    setLoadingMsgs(false);
    await markRead(storeId);
    autoDraft(storeId, msgs);
  }

  function clearImage() {
    setImagePreview(null);
    setImageFile(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  }

  function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImageFile(file);
    const reader = new FileReader();
    reader.onload = ev => setImagePreview(ev.target?.result as string);
    reader.readAsDataURL(file);
  }

  async function sendMessage() {
    if ((!input.trim() && !imageFile) || !selected || sending) return;
    setSending(true);
    const text = input.trim();
    setInput("");

    try {
      let imageUrl: string | null = null;

      // ── Step 1: compress + convert image to base64 ──
      if (imageFile) {
        try {
          imageUrl = await new Promise<string>((resolve, reject) => {
            const reader = new FileReader();
            reader.onerror = (e) => reject(e);
            reader.onload = (e) => {
              const img = new window.Image();
              img.onerror = reject;
              img.onload = () => {
                const MAX = 800;
                let { width, height } = img;
                if (width > MAX || height > MAX) {
                  if (width > height) { height = Math.round(height * MAX / width); width = MAX; }
                  else { width = Math.round(width * MAX / height); height = MAX; }
                }
                const canvas = document.createElement('canvas');
                canvas.width = width; canvas.height = height;
                canvas.getContext('2d')!.drawImage(img, 0, 0, width, height);
                const compressed = canvas.toDataURL('image/jpeg', 0.6);
                console.log('[Support] compressed base64 length:', compressed.length);
                resolve(compressed);
              };
              img.src = e.target?.result as string;
            };
            reader.readAsDataURL(imageFile);
          });
          clearImage();
        } catch (e) {
          console.error('[Support] image compression failed:', e);
          alert('ไม่สามารถแปลงรูปได้: ' + String(e));
          setSending(false);
          return;
        }
      }

      // ── Step 2: send message ──
      console.log('[Support] sending to:', `${API}/${selected}`, 'imageUrl length:', imageUrl?.length ?? 0);
      const res = await fetch(`${API}/${selected}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ senderRole: "admin", senderName: "Admin", message: text, imageUrl }),
      });

      console.log('[Support] POST status:', res.status);

      if (res.ok) {
        const msg: Message = await res.json();
        console.log('[Support] message saved, image_url length:', msg.image_url?.length ?? 0);
        setMessages(prev => [...prev, msg]);
      } else {
        const errText = await res.text();
        console.error('[Support] POST failed:', res.status, errText);
        alert(`ส่งข้อความไม่สำเร็จ (${res.status}): ${errText}`);
      }
    } catch (e) {
      console.error('[Support] sendMessage error:', e);
      alert('เกิดข้อผิดพลาด: ' + String(e));
    }
    setSending(false);
  }

  const filtered = threads.filter(t =>
    (t.store_name ?? t.store_id).toLowerCase().includes(search.toLowerCase())
  );

  const selectedThread = threads.find(t => t.store_id === selected);

  return (
    <div className="flex flex-1 overflow-hidden h-full">
      {/* ── Thread List ── */}
      <aside className="w-full md:w-80 shrink-0 border-r border-surface-container-highest flex flex-col bg-surface-container-lowest">
        <div className="px-4 py-4 border-b border-surface-container-highest">
          <h2 className="text-headline-sm text-on-surface font-bold mb-3 flex items-center gap-2">
            <span className="material-symbols-outlined text-primary-container">support_agent</span>
            Support Inbox
          </h2>
          <div className="relative">
            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-secondary text-[18px]">search</span>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="ค้นหาร้านค้า..."
              className="w-full bg-surface-container border border-outline-variant rounded-full py-2 pl-9 pr-4 text-body-sm text-on-surface focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto">
          {filtered.length === 0 && (
            <div className="p-8 text-center text-secondary">
              <span className="material-symbols-outlined text-4xl mb-2 block">inbox</span>
              <p className="text-body-sm">ยังไม่มีข้อความ</p>
            </div>
          )}
          {filtered.map(t => (
            <button
              key={t.store_id}
              onClick={() => selectThread(t.store_id)}
              className={`w-full text-left px-4 py-4 border-b border-surface-container-highest transition-colors hover:bg-surface-container/60
                ${selected === t.store_id ? "bg-primary-container/10 border-l-4 border-l-primary-container" : ""}`}
            >
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-full bg-primary-container/20 flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-primary-container text-xl">storefront</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between mb-0.5">
                    <span className="text-label-lg text-on-surface font-semibold truncate">
                      {t.store_name ?? `Store ${t.store_id}`}
                    </span>
                    <span className="text-body-xs text-secondary shrink-0 ml-2">{timeAgo(t.last_at)}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    {t.last_role === "admin" && (
                      <span className="text-body-xs text-secondary">คุณ: </span>
                    )}
                    <p className="text-body-sm text-secondary truncate flex-1">
                      {t.last_image_url && !t.last_message ? "📷 รูปภาพ" : (t.last_message ?? "ยังไม่มีข้อความ")}
                    </p>
                    {t.unread_count > 0 && (
                      <span className="ml-1 bg-primary-container text-white text-xs font-bold rounded-full min-w-[20px] h-5 flex items-center justify-center px-1 shrink-0">
                        {t.unread_count}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </button>
          ))}
        </div>
      </aside>

      {/* ── Chat Area ── */}
      <div className="flex-1 flex flex-col min-w-0 bg-surface-bright">
        {!selected ? (
          <div className="flex-1 flex flex-col items-center justify-center text-secondary">
            <div className="w-20 h-20 rounded-full bg-primary-container/10 flex items-center justify-center mb-4">
              <span className="material-symbols-outlined text-primary-container text-4xl">chat</span>
            </div>
            <p className="text-headline-sm text-on-surface mb-1">Support Chat</p>
            <p className="text-body-md text-secondary">เลือกการสนทนาจากด้านซ้าย</p>
          </div>
        ) : (
          <>
            {/* Chat header */}
            <div className="px-6 py-4 bg-surface-container-lowest border-b border-surface-container-highest flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-primary-container/20 flex items-center justify-center">
                <span className="material-symbols-outlined text-primary-container">storefront</span>
              </div>
              <div>
                <p className="text-label-lg text-on-surface font-bold">
                  {selectedThread?.store_name ?? `Store ${selected}`}
                </p>
                <p className="text-body-xs text-secondary">Store ID: {selected}</p>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-4 py-6 space-y-3">
              {loadingMsgs ? (
                <div className="flex justify-center pt-12">
                  <div className="w-8 h-8 border-2 border-primary-container border-t-transparent rounded-full animate-spin" />
                </div>
              ) : messages.length === 0 ? (
                <div className="text-center text-secondary pt-12">
                  <span className="material-symbols-outlined text-3xl mb-2 block">chat_bubble_outline</span>
                  <p className="text-body-sm">ยังไม่มีข้อความ — เริ่มสนทนาได้เลย</p>
                </div>
              ) : (
                messages.map(msg => {
                  const isAdmin = msg.sender_role === "admin";
                  return (
                    <div key={msg.id} className={`flex ${isAdmin ? "justify-end" : "justify-start"}`}>
                      {!isAdmin && (
                        <div className="w-8 h-8 rounded-full bg-primary-container/15 flex items-center justify-center shrink-0 mr-2 mt-1">
                          <span className="material-symbols-outlined text-primary-container text-[16px]">storefront</span>
                        </div>
                      )}
                      <div className={`max-w-[72%] ${isAdmin ? "items-end" : "items-start"} flex flex-col`}>
                        <div className={`px-4 py-2.5 rounded-2xl text-body-md shadow-sm
                          ${isAdmin
                            ? "bg-primary-container text-white rounded-br-sm"
                            : "bg-surface-container-lowest text-on-surface rounded-bl-sm border border-surface-container-highest"
                          }`}
                        >
                          {msg.image_url && (() => {
                            const src = msg.image_url.startsWith('data:')
                              ? msg.image_url
                              : `${BACKEND}${msg.image_url}`;
                            return (
                              <a href={src} target="_blank" rel="noopener noreferrer">
                                {/* eslint-disable-next-line @next/next/no-img-element */}
                                <img
                                  src={src}
                                  alt="รูปภาพ"
                                  className="max-w-full rounded-xl mb-1 cursor-pointer hover:opacity-90 transition-opacity"
                                  style={{ maxHeight: 260 }}
                                  onError={(e) => {
                                    const t = e.currentTarget;
                                    t.style.display = 'none';
                                    const p = document.createElement('div');
                                    p.className = 'text-xs text-on-surface-variant bg-surface-container px-3 py-2 rounded-xl mb-1';
                                    p.textContent = '📷 รูปภาพหมดอายุ';
                                    t.parentElement?.appendChild(p);
                                  }}
                                />
                              </a>
                            );
                          })()}
                          {msg.message && <span>{msg.message}</span>}
                        </div>
                        <span className="text-body-xs text-secondary mt-1 px-1">
                          {formatTime(msg.created_at)}
                        </span>
                      </div>
                    </div>
                  );
                })
              )}
              <div ref={bottomRef} />
            </div>

            {/* Image preview */}
            {imagePreview && (
              <div className="px-4 pb-2">
                <div className="relative inline-block">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={imagePreview} alt="preview" className="h-24 rounded-xl border border-outline-variant object-cover" />
                  <button
                    onClick={clearImage}
                    className="absolute -top-2 -right-2 w-6 h-6 bg-error text-white rounded-full flex items-center justify-center text-xs shadow"
                  >
                    <span className="material-symbols-outlined text-[14px]">close</span>
                  </button>
                </div>
              </div>
            )}

            {/* Input */}
            <div className="px-4 py-4 bg-surface-container-lowest border-t border-surface-container-highest">
              {/* AI drafting indicator */}
              {aiDrafting && (
                <div className="mb-2 flex items-center gap-1.5 text-body-xs text-primary-container">
                  <div className="w-3 h-3 border-2 border-primary-container border-t-transparent rounded-full animate-spin" />
                  <span>AI กำลังร่างคำตอบ...</span>
                </div>
              )}

              <div className="flex items-end gap-2">
                {/* Image pick button */}
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center text-secondary hover:bg-surface-container-highest transition-colors shrink-0"
                  title="แนบรูปภาพ"
                >
                  <span className="material-symbols-outlined text-[20px]">image</span>
                </button>
                <input ref={fileInputRef} type="file" accept="image/*" className="hidden" onChange={onFileChange} />

                <div className="flex-1 bg-surface-container border border-outline-variant rounded-2xl px-4 py-2">
                  <textarea
                    ref={inputRef}
                    value={input}
                    onChange={e => setInput(e.target.value)}
                    onKeyDown={e => {
                      if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); }
                    }}
                    placeholder="พิมพ์ข้อความถึงร้านค้า..."
                    rows={1}
                    className="w-full bg-transparent text-body-md text-on-surface resize-none focus:outline-none max-h-32 overflow-y-auto"
                    style={{ lineHeight: "1.5" }}
                  />
                </div>
                <button
                  onClick={sendMessage}
                  disabled={(!input.trim() && !imageFile) || sending}
                  className="w-11 h-11 rounded-full bg-primary-container flex items-center justify-center text-white transition-opacity disabled:opacity-40 hover:bg-primary shrink-0"
                >
                  {sending
                    ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    : <span className="material-symbols-outlined text-[20px]">send</span>
                  }
                </button>
              </div>
              <p className="text-body-xs text-secondary mt-1.5 pl-1">Enter ส่ง · Shift+Enter ขึ้นบรรทัดใหม่</p>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
