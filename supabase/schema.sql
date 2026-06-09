-- 오늘탈까 Supabase schema with per-user RLS isolation.
-- Apply on a fresh project: copy the entire file into Supabase SQL Editor and run.
-- Re-running on an existing project is safe (idempotent guards), but RLS policies
-- need to be dropped manually before re-running if their bodies changed.

create table if not exists public.rides (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text null,
  started_at timestamptz not null,
  ended_at timestamptz null,
  duration_seconds integer not null default 0,
  moving_seconds integer null,
  distance_meters double precision not null default 0,
  average_speed_kmh double precision not null default 0,
  max_speed_kmh double precision not null default 0,
  start_lat double precision null,
  start_lng double precision null,
  end_lat double precision null,
  end_lng double precision null,
  weather_snapshot jsonb null,
  air_quality_snapshot jsonb null,
  memo text null,
  share_card_url text null,
  sync_status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ride_points (
  id uuid primary key,
  ride_id uuid not null references public.rides(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  recorded_at timestamptz not null,
  lat double precision not null,
  lng double precision not null,
  altitude double precision null,
  speed_mps double precision null,
  horizontal_accuracy double precision null,
  sequence integer not null,
  created_at timestamptz not null default now()
);

create index if not exists ride_points_ride_id_sequence_idx
  on public.ride_points (ride_id, sequence);

create index if not exists ride_points_user_id_idx
  on public.ride_points (user_id);

create index if not exists rides_user_id_started_at_idx
  on public.rides (user_id, started_at desc);

create table if not exists public.ride_photos (
  id uuid primary key,
  ride_id uuid not null references public.rides(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  local_identifier text null,
  storage_path text null,
  created_at timestamptz not null default now()
);

-- Row Level Security: each row visible/writable only by its owning user.

alter table public.rides enable row level security;
alter table public.ride_points enable row level security;
alter table public.ride_photos enable row level security;

drop policy if exists "rides_owner_all" on public.rides;
create policy "rides_owner_all" on public.rides
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "ride_points_owner_all" on public.ride_points;
create policy "ride_points_owner_all" on public.ride_points
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "ride_photos_owner_all" on public.ride_photos;
create policy "ride_photos_owner_all" on public.ride_photos
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
