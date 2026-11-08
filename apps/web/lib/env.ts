import { z } from "zod";

/**
 * Lecture des variables d'environnement.
 * Une variable absente ne fait pas planter l'app : la fonctionnalité
 * correspondante est signalée « À connecter » dans l'interface.
 */
const schema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url().optional(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1).optional(),
  NEXT_PUBLIC_APP_URL: z.string().url().optional(),
  WORKER_URL: z.string().url().optional(),
  STRIPE_SECRET_KEY: z.string().min(1).optional(),
  TIKTOK_CLIENT_KEY: z.string().min(1).optional(),
});

export const env = schema.parse({
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL || undefined,
  NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || undefined,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL || undefined,
  WORKER_URL: process.env.WORKER_URL || undefined,
  STRIPE_SECRET_KEY: process.env.STRIPE_SECRET_KEY || undefined,
  TIKTOK_CLIENT_KEY: process.env.TIKTOK_CLIENT_KEY || undefined,
});

export type IntegrationState = "connected" | "missing";

export function integrations(): Record<string, IntegrationState> {
  return {
    Supabase: env.NEXT_PUBLIC_SUPABASE_URL && env.NEXT_PUBLIC_SUPABASE_ANON_KEY ? "connected" : "missing",
    "Worker vidéo (Railway)": env.WORKER_URL ? "connected" : "missing",
    Stripe: env.STRIPE_SECRET_KEY ? "connected" : "missing",
    TikTok: env.TIKTOK_CLIENT_KEY ? "connected" : "missing",
  };
}
