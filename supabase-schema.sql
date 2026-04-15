-- ═══════════════════════════════════════════════════════════════
--  484.sk — Supabase Schema
--  Spusti celý tento súbor v Supabase → SQL Editor → New query
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Tabuľka inzerátov ──────────────────────────────────────
create table if not exists inzeraty (
  id            bigint generated always as identity primary key,
  created_at    timestamptz default now() not null,
  updated_at    timestamptz default now() not null,

  -- Základné info
  nazov         text        not null,
  popis         text        not null,
  cena          numeric     not null,
  typ           text        not null check (typ in ('dom','byt','pozemok','kancelaria')),
  kraj          text        not null,
  obec          text        not null,

  -- Parametre nehnuteľnosti
  uzitk_plocha  numeric,           -- m²
  zastav_plocha numeric,           -- m²
  pozemok       numeric,           -- m²
  dispozicia    text,              -- napr. "3+2"
  energy_class  text,              -- A0, A1, B...
  stav          text,              -- Novostavba, Pôvodný stav...
  poschodie     text,
  prizemie      text,
  na_kluc       boolean default false,
  vlastnictvo   text default 'Osobné',

  -- Extra atribúty (flexibilné key-value páry)
  extra_specs   jsonb default '[]'::jsonb,

  -- Fotky (pole URL z Supabase Storage)
  foto_urls     jsonb default '[]'::jsonb,

  -- Metadáta
  aktivny       boolean default true,
  badge         text default 'NOVÝ',   -- badge na karte
  folder        text                   -- priečinok v Storage, napr. "dom1"
);

-- ── 2. Auto-update updated_at ─────────────────────────────────
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_inzeraty_updated_at
  before update on inzeraty
  for each row execute function update_updated_at();

-- ── 3. Row Level Security ─────────────────────────────────────
alter table inzeraty enable row level security;

-- Verejný read (web načíta inzeráty bez loginu)
create policy "public_read" on inzeraty
  for select using (aktivny = true);

-- Admin write (len autentifikovaný používateľ môže meniť)
create policy "admin_insert" on inzeraty
  for insert with check (auth.role() = 'authenticated');

create policy "admin_update" on inzeraty
  for update using (auth.role() = 'authenticated');

create policy "admin_delete" on inzeraty
  for delete using (auth.role() = 'authenticated');

-- ── 4. Storage bucket pre fotky ──────────────────────────────
-- Spusti ručne v Supabase → Storage → New bucket:
--   Názov: "nehnutelnosti"
--   Public: YES
-- Alebo odkomentuj toto (vyžaduje service_role key):
-- insert into storage.buckets (id, name, public)
-- values ('nehnutelnosti', 'nehnutelnosti', true)
-- on conflict do nothing;

-- ── 5. Seed dát — existujúce 2 domy ─────────────────────────
insert into inzeraty (
  nazov, popis, cena, typ, kraj, obec,
  uzitk_plocha, zastav_plocha, pozemok,
  dispozicia, energy_class, stav,
  prizemie, poschodie,
  na_kluc, vlastnictvo, badge, folder,
  extra_specs, foto_urls
) values
(
  'Moderný 4-izbový rodinný dom Mokrance — Dvojdom č. 1 (Ľavý)',
  'Ponúkame na predaj moderný rodinný dom — ľavú časť dvojdomu situovaného na slepej ulici v obci Mokrance, vzdialený len cca 20 minút jazdy od centra Košíc. Predaj priamo od majiteľa, bez realitnej kancelárie, bez akýchkoľvek provízií.

Dom je novostavba v štandarde ŠTANDARD s plochou strechou systému Fatrafol s kamienkovým zásypom, plastovými oknami a energetickou triedou A0. Objekt je napojený na všetky inžinierske siete. Na požiadanie je možné dokončenie na kľúč.',
  287000, 'dom', 'kosicky', 'Mokrance',
  121, 82, 486.58,
  '3+2', 'A0', 'Novostavba ŠTANDARD',
  '65,63 m²', '55,34 m²',
  true, 'Osobné', 'NOVÝ', 'dom1',
  '[
    {"key":"Strecha","val":"Fatrafol · kamienok"},
    {"key":"Okná","val":"Plastové"},
    {"key":"Terasa / Sklad","val":"Áno / Áno"},
    {"key":"Typ pozemku","val":"Rovina"},
    {"key":"Od Košíc","val":"≈ 20 min"},
    {"key":"Ulica","val":"Slepá ulica"}
  ]'::jsonb,
  '[]'::jsonb
),
(
  'Moderný 4-izbový rodinný dom Mokrance — Dvojdom č. 2 (Pravý)',
  'Ponúkame na predaj moderný rodinný dom — pravú časť dvojdomu v obci Mokrance, vzdialený len cca 20 minút jazdy od centra Košíc. Dom č. 2 disponuje väčším pozemkom (586,62 m²) oproti susednému Domu č. 1. Predaj priamo od majiteľa, bez realitnej kancelárie.

Dom je novostavba v štandarde ŠTANDARD s plochou strechou systému Fatrafol s kamienkovým zásypom, plastovými oknami a energetickou triedou A0. Na požiadanie je možné dokončenie na kľúč.',
  298000, 'dom', 'kosicky', 'Mokrance',
  121, 82, 586.62,
  '3+2', 'A0', 'Novostavba ŠTANDARD',
  '65,63 m²', '55,34 m²',
  true, 'Osobné', 'NOVÝ', 'dom2',
  '[
    {"key":"Strecha","val":"Fatrafol · kamienok"},
    {"key":"Okná","val":"Plastové"},
    {"key":"Terasa / Sklad","val":"Áno / Áno"},
    {"key":"Typ pozemku","val":"Rovina"},
    {"key":"Od Košíc","val":"≈ 20 min"},
    {"key":"Väčší pozemok","val":"Áno"}
  ]'::jsonb,
  '[]'::jsonb
);

-- ── 6. Verifikácia ────────────────────────────────────────────
select id, nazov, cena, typ, kraj from inzeraty;
