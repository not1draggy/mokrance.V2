/* ═══════════════════════════════════════════════════════════════
   484.SK — Konfigurácia
   ═══════════════════════════════════════════════════════════════ */

const CONFIG = {
  // ── Supabase ──────────────────────────────────────────────────
  SUPABASE_URL:     'https://vrzztcgwmmzegkiexgpl.supabase.co',
  SUPABASE_ANON:    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZyenp0Y2d3bW16ZWdraWV4Z3BsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNTA5NjUsImV4cCI6MjA5MTgyNjk2NX0.tHAGNJdnjW1O7fH8jbHVzI52il9HFhOuDMxzVXj6TFE',

  // ── Edge Functions ────────────────────────────────────────────
  TRANSLATE_FN:     'https://vrzztcgwmmzegkiexgpl.supabase.co/functions/v1/rapid-api',

  // ── Jazyky ────────────────────────────────────────────────────
  LANGUAGES: [
    { code: 'sk', label: 'SK', flag: '🇸🇰', deepl: null,    name: 'Slovenčina'  },
    { code: 'en', label: 'EN', flag: '🇬🇧', deepl: 'EN-GB', name: 'English'     },
    { code: 'de', label: 'DE', flag: '🇩🇪', deepl: 'DE',    name: 'Deutsch'     },
    { code: 'uk', label: 'UK', flag: '🇺🇦', deepl: 'UK',    name: 'Українська'  },
  ],

  // ── Kontakt ───────────────────────────────────────────────────
  TEL_1:            '0905323484',
  TEL_2:            '0919067725',
  TEL_1_FORMAT:     '0905 323 484',
  TEL_2_FORMAT:     '0919 067 725',

  // ── Storage ───────────────────────────────────────────────────
  BUCKET:           'nehnutelnosti',

  // ── Telegram notifikácie (CallMeBot) ─────────────────────────
  TELEGRAM_USER:    'notdraggy',   // tvoj Telegram username bez @

  // ── Site ──────────────────────────────────────────────────────
  SITE_NAME:        '484.sk',
  SITE_DESC:        'Predaj nehnuteľností — priamy predaj od majiteľa, bez provízií.',
};
