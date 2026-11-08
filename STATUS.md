# État des fonctionnalités

Légende : **Fonctionnel** · **Partiel** · **À connecter** · **À faire**

| Domaine | État | Détail |
| --- | --- | --- |
| Monorepo GitHub + CI | Fonctionnel | `.github/workflows/ci.yml` : typecheck + build web, tests + build Docker worker |
| Frontend Next.js (Vercel) | Fonctionnel | Page d'accueil + `/api/health` (état des intégrations) |
| Worker vidéo (Railway) | Fonctionnel | FastAPI + FFmpeg, `/health` |
| Schéma base de données + RLS | Partiel | Migration `supabase/migrations/20261108000000_initial_schema.sql` écrite ; à appliquer dès que le projet Supabase existe |
| Projet Supabase | À connecter | Limite de 2 projets gratuits atteinte sur le compte : mettre un projet en pause ou passer en Pro |
| Authentification | À faire | Phase 2 |
| Import vidéo | À faire | Phase 3 |
| Découpage FFmpeg | À faire | Phase 4 |
| Analyse IA | À connecter | Clé `ANTHROPIC_API_KEY` ou `OPENAI_API_KEY` requise (phase 5) |
| Organisation des épisodes | À faire | Phase 6 |
| Export | À faire | Phase 7 |
| TikTok | À connecter | App TikTok for Developers + audit Content Posting API (phase 8) |
| Stripe | À connecter | Clés Stripe (phase 9) |
