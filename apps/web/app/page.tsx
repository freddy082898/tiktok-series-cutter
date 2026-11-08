import { integrations } from "@/lib/env";

export const dynamic = "force-dynamic";

const steps = [
  "Importer une vidéo ou coller un lien",
  "Choisir le mode de découpage",
  "Lancer l'analyse IA",
  "Visualiser les épisodes",
  "Réorganiser et modifier",
  "Prévisualiser",
  "Connecter TikTok",
  "Programmer ou publier",
];

export default function Home() {
  const state = integrations();
  return (
    <main className="mx-auto max-w-4xl px-6 py-16">
      <p className="text-sm uppercase tracking-widest text-[var(--accent-2)]">Phase 0 — fondations</p>
      <h1 className="mt-3 text-4xl font-semibold md:text-5xl">TikTok Series Cutter</h1>
      <p className="mt-4 max-w-2xl text-lg text-[var(--muted)]">
        Transformez une longue vidéo en série d&apos;épisodes TikTok cohérents, classés dans le bon ordre et prêts à publier.
      </p>

      <section className="mt-12 grid gap-3 sm:grid-cols-2">
        {steps.map((s, i) => (
          <div key={s} className="rounded-2xl border border-[var(--border)] bg-[var(--card)] p-4">
            <span className="text-[var(--accent)]">{String(i + 1).padStart(2, "0")}</span>
            <span className="ml-3">{s}</span>
          </div>
        ))}
      </section>

      <section className="mt-12">
        <h2 className="text-xl font-medium">État des intégrations</h2>
        <ul className="mt-4 divide-y divide-[var(--border)] rounded-2xl border border-[var(--border)] bg-[var(--card)]">
          {Object.entries(state).map(([name, s]) => (
            <li key={name} className="flex items-center justify-between px-4 py-3">
              <span>{name}</span>
              <span className={s === "connected" ? "text-emerald-400" : "text-amber-400"}>
                {s === "connected" ? "Connecté" : "À connecter"}
              </span>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
