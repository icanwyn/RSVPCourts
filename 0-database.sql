-- ============================================================
--  RSVP Courts — Fresh Schema
--  Run this in Supabase → SQL Editor → New Query
--  If you ran previous versions, this is safe to run again
-- ============================================================

-- Drop old tables cleanly and start fresh
drop table if exists queue cascade;
drop table if exists court_players cascade;
drop table if exists courts cascade;
drop table if exists players cascade;
drop table if exists gyms cascade;

-- GYMS
create table gyms (
  id                uuid primary key default gen_random_uuid(),
  owner_id          uuid references auth.users(id) on delete cascade,
  name              text not null,
  slug              text not null unique,
  sport             text not null default 'Badminton',
  num_courts        int  not null default 4,
  players_per_court int  not null default 4,
  session_mins      int  not null default 30,
  max_queue         int  not null default 6,
  show_wait         boolean not null default true,
  primary_color     text not null default '#1a7a4a',
  created_at        timestamptz default now()
);

-- PLAYERS
create table players (
  id            uuid primary key default gen_random_uuid(),
  gym_id        uuid references gyms(id) on delete cascade,
  name          text not null,
  pass_type     text not null default 'day',
  code          text not null,
  status        text not null default 'pending',
  locked_court  int  default null,
  expires_at    timestamptz not null,
  issued_at     timestamptz default now(),
  unique(gym_id, code)
);

-- COURTS
create table courts (
  id            uuid primary key default gen_random_uuid(),
  gym_id        uuid references gyms(id) on delete cascade,
  court_number  int  not null,
  session_start timestamptz default null,
  unique(gym_id, court_number)
);

-- COURT PLAYERS
create table court_players (
  id            uuid primary key default gen_random_uuid(),
  gym_id        uuid references gyms(id) on delete cascade,
  court_number  int  not null,
  player_id     uuid references players(id) on delete cascade,
  joined_at     timestamptz default now(),
  unique(gym_id, player_id)
);

-- QUEUE
create table queue (
  id            uuid primary key default gen_random_uuid(),
  gym_id        uuid references gyms(id) on delete cascade,
  court_number  int  not null,
  player_id     uuid references players(id) on delete cascade,
  position      int  not null default 1,
  queued_at     timestamptz default now()
);

-- ── ROW LEVEL SECURITY ──────────────────────────────────────
alter table gyms          enable row level security;
alter table players       enable row level security;
alter table courts        enable row level security;
alter table court_players enable row level security;
alter table queue         enable row level security;

-- Gyms: owner has full access, everyone can read (for kiosk)
create policy "owner full gyms"   on gyms for all    using (auth.uid() = owner_id) with check (auth.uid() = owner_id);
create policy "public read gyms"  on gyms for select using (true);

-- Players, courts, court_players, queue: open read/write for kiosk flow
create policy "open players"       on players       for all using (true) with check (true);
create policy "open courts"        on courts        for all using (true) with check (true);
create policy "open court_players" on court_players for all using (true) with check (true);
create policy "open queue"         on queue         for all using (true) with check (true);

-- ── REALTIME ────────────────────────────────────────────────
alter publication supabase_realtime add table players;
alter publication supabase_realtime add table courts;
alter publication supabase_realtime add table court_players;
alter publication supabase_realtime add table queue;
