# 484.sk — Pridať inzerát → Supabase → CallMeBot (notifikácia do mobilu)

Tok: **Formulár** → insert do Supabase `listings` (status `pending`) + upload fotiek do Storage → **Database Webhook** spustí **Edge Function** → zavolá **CallMeBot** → tebe príde **WhatsApp** do mobilu → v admin paneli **schváliš** → status `approved` → inzerát sa zobrazí na webe.

CallMeBot kľúč je vždy len na serveri (Edge Function) — nikdy vo frontende.

---

## Krok 0 — CallMeBot API kľúč (5 min)

WhatsApp varianta:
1. Pridaj si do kontaktov číslo **+34 644 84 71 89** (CallMeBot).
2. Pošli mu WhatsApp správu: `I allow callmebot to send me messages`
3. Príde ti odpoveď s **apikey** (napr. `123456`).

Rýchly test priamo v prehliadači:
```
https://api.callmebot.com/whatsapp.php?phone=+421905323484&text=test&apikey=TVOJ_KLUC
```
(Existujú aj Telegram / Signal varianty — postup je rovnaký.)

---

## Krok 1 — Supabase tabuľka + storage

Rozšírenie tvojho `supabase-schema.sql`:
```sql
create table if not exists listings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  status text default 'pending',        -- pending | approved | rejected
  nazov text not null,
  popis text not null,
  cena numeric not null,
  typ text not null,                    -- dom | byt | pozemok | kancelaria
  obec text not null,
  kraj text not null,
  plocha numeric,
  dispozicia text,
  photos text[],                        -- verejné URL fotiek
  submitter_name text,
  submitter_email text,
  submitter_phone text
);

alter table listings enable row level security;

-- verejnosť vidí len schválené inzeráty
create policy "public read approved"
  on listings for select using (status = 'approved');

-- ktokoľvek (anon) môže vložiť len pending
create policy "anyone insert pending"
  on listings for insert with check (status = 'pending');
```

Storage: vytvor **public** bucket `listing-photos`.

---

## Krok 2 — Edge Function (volá CallMeBot, kľúč skrytý)

`supabase/functions/notify-listing/index.ts`:
```ts
import { serve } from "https://deno.land/std/http/server.ts";

serve(async (req) => {
  const { record } = await req.json();           // riadok z DB webhooku
  const phone  = Deno.env.get("ADMIN_PHONE");    // napr. +421905323484
  const apikey = Deno.env.get("CALLMEBOT_APIKEY");

  const text =
    `🏠 Nový inzerát na 484.sk\n` +
    `${record.nazov}\n` +
    `${record.cena} € · ${record.obec}, ${record.kraj}\n` +
    `Kontakt: ${record.submitter_name} ${record.submitter_phone ?? ""} ${record.submitter_email}\n` +
    `Schváliť: https://484.sk/admin.html`;

  const url = `https://api.callmebot.com/whatsapp.php` +
    `?phone=${encodeURIComponent(phone!)}` +
    `&text=${encodeURIComponent(text)}` +
    `&apikey=${apikey}`;

  await fetch(url);
  return new Response("ok");
});
```

Nasadenie:
```bash
supabase secrets set ADMIN_PHONE=+421905323484 CALLMEBOT_APIKEY=TVOJ_KLUC
supabase functions deploy notify-listing --no-verify-jwt
```

---

## Krok 3 — Spustenie pri novom inzeráte (Database Webhook)

Supabase Dashboard → **Database → Webhooks → Create a new hook**:
- **Table:** `listings`
- **Events:** `INSERT`
- **Type:** Supabase Edge Function → `notify-listing`

Webhook pošle nový riadok (`record`) do funkcie → CallMeBot → notifikácia ti príde do mobilu.
(Alternatíva: DB trigger + `pg_net`, ale webhook je jednoduchší a stačí.)

---

## Krok 4 — Frontend submit (nahradí simuláciu v prototype)

`config.js` už máš so `SUPABASE_URL` a anon kľúčom. Submit handler:
```js
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function submitListing(form, files) {
  // 1. upload fotiek
  const urls = [];
  for (const file of files) {
    const path = `${crypto.randomUUID()}-${file.name}`;
    await supabase.storage.from("listing-photos").upload(path, file);
    const { data } = supabase.storage.from("listing-photos").getPublicUrl(path);
    urls.push(data.publicUrl);
  }

  // 2. insert (status pending → webhook → Edge Function → CallMeBot)
  const { error } = await supabase.from("listings").insert({
    nazov: form.nazov, popis: form.popis, cena: Number(form.cena),
    typ: form.typ, obec: form.obec, kraj: form.kraj,
    plocha: form.plocha ? Number(form.plocha) : null,
    dispozicia: form.dispozicia || null,
    photos: urls,
    submitter_name: form.name, submitter_email: form.email,
    submitter_phone: form.phone || null,
    status: "pending",
  });

  if (error) throw error;
  // → zobraz success obrazovku; tebe medzitým príde WhatsApp
}
```

---

## Krok 5 — Admin schválenie (`admin.html`)

```js
// načítaj čakajúce
const { data: pending } = await supabase
  .from("listings").select("*").eq("status", "pending")
  .order("created_at", { ascending: false });

// schváliť / zamietnuť
await supabase.from("listings").update({ status: "approved" }).eq("id", id);
await supabase.from("listings").update({ status: "rejected" }).eq("id", id);

// úprava inzerátu (tlačidlo „Upraviť" v admin paneli)
await supabase.from("listings").update({
  nazov, popis, cena, typ, obec, kraj, plocha, dispozicia
}).eq("id", id);
```
Po `approved` sa inzerát automaticky objaví na webe (public read policy).
> Admin operácie rob cez prihlásený **service_role** alebo Supabase Auth — nie cez verejný anon kľúč. Pridaj policy na update len pre admina.

---

## Bezpečnosť — checklist
- CallMeBot kľúč len v **Edge Function secrets**, nikdy vo frontende.
- **Honeypot** pole (už v repo) + rate-limit na insert (napr. cez Edge Function alebo `pg` policy).
- **RLS:** anon môže len `insert pending` a `select approved`.
- Validácia veľkosti / typu fotiek pred uploadom (max 8, do 5 MB, image/*).

---

## Telegram varianta (aktuálne použitá v prototype)
Notifikácie idú cez **Telegram CallMeBot**, nie WhatsApp:
1. V Telegrame napíš botovi **@CallMeBot_txtbot** správu `/start`.
2. Bot ti potvrdí, že môže posielať správy na tvoj účet.
3. Posielanie správy: `https://api.callmebot.com/text.php?user=@TVOJ_USERNAME&text=Sprava`

> Pozn.: `user` má byť tvoj **osobný** Telegram username (napr. `@jan`), nie username bota. V prototype je predvyplnené `@CallMeBot_txtbot` — uprav ho cez Tweaks na svoj username.

## Poznámka k prototypu (`484 Landing.dc.html` + `484 Admin.dc.html`)
Telegram háčik je dostupný cez **Tweaks** (`telegramUser`):
- **Landing** — pri odoslaní nového inzerátu ti príde notifikácia na Telegram.
- **Admin** — tlačidlo **„Spätná väzba"** pošle vývojárovi správu (chyba / vylepšenie) na ten istý Telegram.

Funguje to priamo z prehliadača na testovanie. Produkčne presuň volanie CallMeBotu do **Edge Function** (rovnaký tok ako vyššie, len endpoint `text.php`), aby bol kľúč/username skrytý na serveri.
