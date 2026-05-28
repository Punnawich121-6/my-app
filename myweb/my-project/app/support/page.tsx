import { Suspense } from "react";
import Navbar from "../component/navbar";
import SupportClient from "./SupportClient";

export const dynamic = "force-dynamic";

export default function SupportPage() {
  return (
    <>
      <Navbar />
      <main className="md:ml-64 pt-16 h-screen flex flex-col">
        <Suspense fallback={null}>
          <SupportClient />
        </Suspense>
      </main>
    </>
  );
}
