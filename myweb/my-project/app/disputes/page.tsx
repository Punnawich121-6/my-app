import { Suspense } from "react";
import { redirect } from "next/navigation";
import { verifySession } from "@/app/lib/session";
import Navbar from "../component/navbar";
import DisputesClient from "./DisputesClient";

export const dynamic = "force-dynamic";

export default async function DisputesPage() {
  const session = await verifySession();
  if (!session) redirect("/login");

  return (
    <>
      <Navbar />
      <main className="pt-20 md:pt-24 pb-20 md:pb-8 px-4 md:px-8 md:ml-64 min-h-screen">
        <div className="mb-6">
          <h2 className="text-headline-lg text-on-background">AI Dispute Autopilot</h2>
          <p className="text-body-sm text-on-surface-variant mt-1">
            ระบบ AI วิเคราะห์และตัดสิน dispute อัตโนมัติ — confidence ≥80% AI แก้เอง, 60–79% รอ admin, &lt;60% escalate
          </p>
        </div>
        <Suspense fallback={null}>
          <DisputesClient />
        </Suspense>
      </main>
    </>
  );
}
