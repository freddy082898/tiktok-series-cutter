-- TikTok Series Cutter — schéma initial (phase 0/1)
-- Toutes les tables métier ont la RLS activée : un utilisateur ne voit que ses données.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Formules (modifiables depuis l'admin, sans redéploiement)
-- ---------------------------------------------------------------------------
create table public.plans (
  id text primary key,                       -- 'free' | 'pro' | 'business'
  name text not null,
  stripe_price_monthly text,
  stripe_price_yearly text,
  projects_per_month int not null,
  minutes_per_month int not null,
  storage_bytes bigint not null,
  max_upload_bytes bigint not null,
  max_source_minutes int not null,
  tiktok_accounts int not null,
  ai_modes boolean not null default false,
  auto_subtitles boolean not null default false,
  watermark boolean not null default true,
  scheduling boolean not null default false,
  priority int not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.plans
  (id, name, projects_per_month, minutes_per_month, storage_bytes, max_upload_bytes, max_source_minutes, tiktok_accounts, ai_modes, auto_subtitles, watermark, scheduling, priority)
values
  ('free',     'Free',     2,   30,   2147483648,   524288000,   20,  1, false, false, true,  false, 0),
  ('pro',      'Pro',      30,  600,  53687091200,  4294967296,  120, 1, true,  true,  false, false, 1),
  ('business', 'Business', 200, 3000, 268435456000, 10737418240, 240, 5, true,  true,  false, true,  2);

-- ---------------------------------------------------------------------------
-- Profils
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  role text not null default 'user' check (role in ('user', 'admin')),
  plan_id text not null default 'free' references public.plans (id),
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Projets, vidéos sources, épisodes
-- ---------------------------------------------------------------------------
create table public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null,
  cut_mode text not null default 'balanced' check (cut_mode in ('auto', 'balanced', 'custom', 'smart')),
  target_seconds int not null default 60 check (target_seconds between 10 and 600),
  order_locked boolean not null default false,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.projects (user_id);

create table public.source_videos (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  storage_path text not null,
  origin text not null check (origin in ('upload', 'url')),
  origin_url text,
  rights_confirmed_at timestamptz not null,
  size_bytes bigint,
  duration_seconds numeric,
  width int,
  height int,
  status text not null default 'uploaded' check (status in ('uploaded', 'probing', 'ready', 'rejected', 'error')),
  error text,
  created_at timestamptz not null default now()
);
create index on public.source_videos (project_id);

create table public.episodes (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  position int not null,
  title text not null default '',
  caption text not null default '' check (char_length(caption) <= 2200),
  hashtags text[] not null default '{}',
  start_seconds numeric not null,
  end_seconds numeric not null check (end_seconds > start_seconds),
  thumbnail_path text,
  export_path text,
  needs_reexport boolean not null default true,
  status text not null default 'to_review' check (status in (
    'processing', 'to_review', 'ready', 'scheduled', 'sent_as_draft',
    'publishing', 'published', 'publish_failed', 'error'
  )),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (project_id, position) deferrable initially deferred
);
create index on public.episodes (project_id);

-- ---------------------------------------------------------------------------
-- Jobs (traitements asynchrones consommés par le worker Railway)
-- ---------------------------------------------------------------------------
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  project_id uuid references public.projects (id) on delete cascade,
  kind text not null check (kind in ('probe', 'analyze', 'render_preview', 'export', 'publish', 'cleanup')),
  payload jsonb not null default '{}',
  status text not null default 'queued' check (status in ('queued', 'running', 'done', 'failed')),
  progress int not null default 0 check (progress between 0 and 100),
  step text,
  attempts int not null default 0,
  max_attempts int not null default 3,
  priority int not null default 0,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.jobs (status, priority desc, created_at);

-- ---------------------------------------------------------------------------
-- TikTok et publications
-- Les jetons sont chiffrés par l'application (TOKEN_ENCRYPTION_KEY) et ne sont
-- jamais lisibles côté client : aucune politique SELECT sur ces colonnes.
-- ---------------------------------------------------------------------------
create table public.tiktok_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  open_id text not null,
  display_name text,
  avatar_url text,
  access_token_enc text,
  refresh_token_enc text,
  token_expires_at timestamptz,
  scopes text[] not null default '{}',
  created_at timestamptz not null default now(),
  unique (user_id, open_id)
);

create table public.publications (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid not null references public.episodes (id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  tiktok_account_id uuid references public.tiktok_accounts (id) on delete set null,
  mode text not null check (mode in ('direct', 'draft', 'manual_export')),
  privacy_level text,
  scheduled_at timestamptz,
  tiktok_publish_id text,
  tiktok_status text,
  status text not null default 'pending' check (status in ('pending', 'sending', 'sent_as_draft', 'published', 'failed', 'cancelled')),
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.publications (status, scheduled_at);

-- ---------------------------------------------------------------------------
-- Abonnements (écrits uniquement par le webhook Stripe, via service_role)
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  id text primary key,                       -- id d'abonnement Stripe
  user_id uuid not null references auth.users (id) on delete cascade,
  plan_id text not null references public.plans (id),
  stripe_customer_id text not null,
  status text not null,
  current_period_end timestamptz,
  cancel_at_period_end boolean not null default false,
  updated_at timestamptz not null default now()
);

create table public.activity_log (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  project_id uuid references public.projects (id) on delete cascade,
  kind text not null,
  message text not null,
  created_at timestamptz not null default now()
);
create index on public.activity_log (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.plans enable row level security;
alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.source_videos enable row level security;
alter table public.episodes enable row level security;
alter table public.jobs enable row level security;
alter table public.tiktok_accounts enable row level security;
alter table public.publications enable row level security;
alter table public.subscriptions enable row level security;
alter table public.activity_log enable row level security;

create policy "plans lisibles par tous" on public.plans for select using (true);

create policy "profil : lecture" on public.profiles for select using ((select auth.uid()) = id);
create policy "profil : mise à jour" on public.profiles for update using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id and role = (select p.role from public.profiles p where p.id = (select auth.uid()))
              and plan_id = (select p.plan_id from public.profiles p where p.id = (select auth.uid())));

create policy "projets : propriétaire" on public.projects for all
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "sources : propriétaire" on public.source_videos for all
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "épisodes : propriétaire" on public.episodes for all
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "jobs : lecture" on public.jobs for select using ((select auth.uid()) = user_id);
create policy "publications : lecture" on public.publications for select using ((select auth.uid()) = user_id);
create policy "abonnements : lecture" on public.subscriptions for select using ((select auth.uid()) = user_id);
create policy "activité : lecture" on public.activity_log for select using ((select auth.uid()) = user_id);
-- tiktok_accounts : aucune politique => inaccessible côté client ; l'API serveur
-- expose uniquement display_name et avatar_url.

-- ---------------------------------------------------------------------------
-- Stockage : buckets privés, un dossier par utilisateur
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('originals', 'originals', false),
       ('episodes', 'episodes', false),
       ('previews', 'previews', false),
       ('thumbnails', 'thumbnails', false),
       ('subtitles', 'subtitles', false)
on conflict (id) do nothing;

create policy "stockage : lecture de son dossier" on storage.objects for select
  using (bucket_id in ('originals', 'episodes', 'previews', 'thumbnails', 'subtitles')
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "stockage : upload dans son dossier" on storage.objects for insert
  with check (bucket_id = 'originals' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "stockage : suppression de son dossier" on storage.objects for delete
  using (bucket_id in ('originals', 'episodes', 'previews', 'thumbnails', 'subtitles')
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Temps réel pour la progression des jobs et le statut des épisodes
alter publication supabase_realtime add table public.jobs, public.episodes;
