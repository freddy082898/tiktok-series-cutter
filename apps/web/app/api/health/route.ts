import { NextResponse } from "next/server";
import { env, integrations } from "@/lib/env";

export const dynamic = "force-dynamic";

export async function GET() {
  let worker: "ok" | "down" | "missing" = "missing";
  if (env.WORKER_URL) {
    try {
      const res = await fetch(`${env.WORKER_URL}/health`, { cache: "no-store", signal: AbortSignal.timeout(5000) });
      worker = res.ok ? "ok" : "down";
    } catch {
      worker = "down";
    }
  }
  return NextResponse.json({ status: "ok", worker, integrations: integrations() });
}
