-- Birthday Marathon: Supabase setup
-- Run this in the SQL editor of a fresh free-tier project.
--
-- Before running: replace YOUR_EMAIL_HERE (2 places) with the email
-- you'll use to log into the dashboard.

create table public.guests (
  id                 bigint generated always as identity primary key,
  created_at         timestamptz not null default now(),
  name               text not null check (char_length(trim(name)) between 1 and 80),
  phone              text not null unique check (char_length(trim(phone)) between 6 and 20),
  dob                date not null check (dob between '1920-01-01' and '2020-12-31'),
  category           text not null check (category in ('5k', '10k', 'spectator')),
  shuttle            boolean not null default false,
  plus_one           boolean not null default false,
  plus_one_name      text check (char_length(plus_one_name) <= 80),
  plus_one_age       int check (plus_one_age between 0 and 110),
  emergency_name     text not null check (char_length(trim(emergency_name)) between 1 and 80),
  emergency_phone    text not null check (char_length(trim(emergency_phone)) between 6 and 20),
  waiver_accepted    boolean not null check (waiver_accepted = true),
  waiver_accepted_at timestamptz not null default now(),
  gift_received      boolean not null default false,  -- ticked at race pack collection
  race_number        int generated always as (id + 100) stored
);

alter table public.guests enable row level security;

-- No anon policies: the public can't read or write the table directly.
-- Registration goes through the RPC below.

create policy "owner can read guests"
  on public.guests for select
  to authenticated
  using ((auth.jwt() ->> 'email') = 'YOUR_EMAIL_HERE');

create policy "owner can update guests"
  on public.guests for update
  to authenticated
  using ((auth.jwt() ->> 'email') = 'YOUR_EMAIL_HERE');

-- Registration RPC: inserts and returns the race number.
create or replace function public.register_guest(
  p_name            text,
  p_phone           text,
  p_dob             date,
  p_category        text,
  p_shuttle         boolean,
  p_plus_one        boolean,
  p_plus_one_name   text,
  p_plus_one_age    int,
  p_emergency_name  text,
  p_emergency_phone text,
  p_waiver_accepted boolean
)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_race_number int;
begin
  if p_category not in ('5k', '10k', 'spectator') then
    raise exception 'invalid category';
  end if;

  if coalesce(p_waiver_accepted, false) is distinct from true then
    raise exception 'waiver must be accepted';
  end if;

  if coalesce(p_plus_one, false)
     and (nullif(trim(coalesce(p_plus_one_name, '')), '') is null or p_plus_one_age is null) then
    raise exception 'plus one requires full name and age';
  end if;

  insert into guests (
    name, phone, dob, category, shuttle,
    plus_one, plus_one_name, plus_one_age,
    emergency_name, emergency_phone, waiver_accepted
  )
  values (
    trim(p_name),
    regexp_replace(trim(p_phone), '\s+', '', 'g'),
    p_dob,
    p_category,
    coalesce(p_shuttle, false),
    coalesce(p_plus_one, false),
    nullif(trim(coalesce(p_plus_one_name, '')), ''),
    p_plus_one_age,
    trim(p_emergency_name),
    regexp_replace(trim(p_emergency_phone), '\s+', '', 'g'),
    true
  )
  returning race_number into v_race_number;

  return json_build_object('race_number', v_race_number, 'already_registered', false);

exception
  when unique_violation then
    select race_number into v_race_number
    from guests
    where phone = regexp_replace(trim(p_phone), '\s+', '', 'g');
    return json_build_object('race_number', v_race_number, 'already_registered', true);
end;
$$;

revoke all on function public.register_guest from public;
grant execute on function public.register_guest to anon;
grant execute on function public.register_guest to authenticated;
