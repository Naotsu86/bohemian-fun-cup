# Bohemian Fun Cup v2.1 – Supabase Auth + Spielerprofil

## 1. Supabase SQL ausführen

Supabase → SQL Editor → New query

Datei ausführen:

supabase/sql/v2_1_profiles_stats_auth.sql

## 2. Ersten Admin setzen

Supabase → Authentication → Users

Deinen User öffnen und die UID kopieren.

Dann im SQL Editor ausführen:

```sql
insert into public.admin_users (user_id)
values ('DEINE-USER-ID-HIER')
on conflict (user_id) do nothing;
```

## 3. Spieler einladen / anlegen

Für den Anfang am einfachsten manuell:

Supabase → Authentication → Users → Add user

- E-Mail eintragen
- Passwort setzen
- Auto Confirm User aktivieren, falls verfügbar

Danach brauchst du die User-ID.

## 4. Spieler mit bestehendem Spieler verknüpfen

Im Table Editor:

- public.players → Spieler-ID kopieren
- auth.users → User-ID kopieren

Dann:

```sql
insert into public.player_profiles (
  user_id,
  player_id,
  display_name
)
values (
  'AUTH-USER-ID',
  'PLAYER-ID',
  'Spielername'
);
```

Optional Stats anlegen:

```sql
insert into public.player_stats (
  player_id,
  strength,
  stamina,
  speed,
  wisdom,
  special_attack
)
values (
  'PLAYER-ID',
  6,
  6,
  6,
  6,
  'Pinguin-Power'
)
on conflict (player_id) do nothing;
```

## 5. Frontend-Dateien

Enthalten sind:

src/services/authV2.js
src/services/playerProfileService.js
src/components/auth/PlayerLoginPanel.vue
src/views/Profile.vue

Diese Dateien sind der Start für Version 2.1.
Die Profile.vue ist noch nicht in die Navigation eingebunden.
Das machen wir im nächsten Schritt, wenn Supabase läuft.

## Wichtig

Die Live-Version auf main bleibt unberührt.
Bitte dieses Paket nur in den Branch v2-avatar-system hochladen.
