create table if not exists public.rides (
  id uuid primary key,
  user_id uuid null,
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

create table if not exists public.ride_photos (
  id uuid primary key,
  ride_id uuid not null references public.rides(id) on delete cascade,
  local_identifier text null,
  storage_path text null,
  created_at timestamptz not null default now()
);

