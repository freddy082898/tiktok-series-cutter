# TikTok Series Cutter

SaaS qui transforme une longue vidéo en série d'épisodes TikTok, classés dans le bon ordre et prêts à publier.

## Architecture

| Dossier | Service | Rôle |
| --- | --- | --- |
| `apps/web` | Vercel (Next.js 15) | Interface, routes API (auth, Stripe, OAuth TikTok, création de jobs) |
| `apps/worker` | Railway (Docker, FastAPI + FFmpeg) | Analyse, transcription, découpe, rendu, publication TikTok |
| `supabase/` | Supabase (Paris) | Postgres + RLS, Auth, Storage, Realtime, file de jobs |

Le traitement vidéo tourne sur Railway car les fonctions Vercel ont une durée et une mémoire limitées.

## Démarrer en local

```bash
cp .env.example apps/web/.env.local     # remplir les valeurs Supabase
cd apps/web && npm install && npm run dev

cd apps/worker && pip install -r requirements-dev.txt
uvicorn app.main:app --reload
```

Base de données : `supabase start` puis `supabase db reset` applique les migrations.

## Déploiement

- **Vercel** : projet lié à ce dépôt, Root Directory `apps/web`.
- **Railway** : service lié à ce dépôt, Root Directory `apps/worker` (Dockerfile + `railway.json`).
- **Supabase** : `supabase db push` applique les migrations.

Voir `STATUS.md` pour l'état de chaque fonctionnalité.
