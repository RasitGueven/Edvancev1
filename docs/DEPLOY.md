# Deployment — Edvance (Vercel)

Die App ist ein **Vite-SPA**; das Backend bleibt **Supabase** (separat gehostet).
Gehostet wird also nur statisches Frontend → Vercel mit Auto-Deploy aus GitHub.
`vercel.json` (Repo-Wurzel) liefert das SPA-Routing (alle Pfade → `index.html`),
damit Deep-Links wie `/admin/qs` auch bei direktem Aufruf/Reload laden.

> Ziel: Lena öffnet eine URL, loggt sich als Admin ein, arbeitet unter `/admin/qs`.
> Kein lokales Setup, kein Build auf ihrer Seite.

## 1. Vercel-Projekt anlegen (einmalig)

1. [vercel.com](https://vercel.com) → mit **GitHub** einloggen → **Add New… → Project**.
2. Repo `rasitgueven/edvancev1` importieren.
3. Framework Preset: **Vite** (wird erkannt). Build-Command & Output kommen aus
   `vercel.json` (`npm run build` → `dist`) — nichts manuell eintragen.
4. **Environment Variables** setzen (für *Production* **und** *Preview*):
   - `VITE_SUPABASE_URL` = deine Supabase-Projekt-URL
   - `VITE_SUPABASE_ANON_KEY` = dein **anon**-Key
   - ⚠️ `SUPABASE_SERVICE_ROLE_KEY` und `ANTHROPIC_API_KEY` **NICHT** eintragen —
     die sind nur server-seitig für `scripts/*`, nie ins Frontend.
5. **Deploy** klicken.

## 2. Welcher Branch geht live

> ⚠️ Wichtig (aktueller Stand): Die ganze aktuelle Arbeit liegt auf **`dev`** —
> `main` ist deutlich älter (u.a. ohne `vercel.json` und ohne `/admin/qs`). Vercel
> baut standardmäßig den Default-Branch `main`, sonst landet ein veralteter Stand live.

- **Jetzt / Pre-Launch:** Settings → Git → **Production Branch: `dev`** setzen.
  Dann spiegelt die Live-URL den aktuellen Stand; jeder `dev`-Push deployt neu.
- **Später / stabile Releases:** auf **`main`** umstellen und `dev → main` mergen
  (Branch-Strategie aus CLAUDE.md). Andere Branches bekommen automatisch Preview-URLs.

## 3. Domain anbinden (Subdomain empfohlen)

1. Vercel → Project → Settings → **Domains** → `studio.edvanceacademy.de` hinzufügen
   (Subdomain hält die Haupt-Domain `edvanceacademy.de` für die spätere Landingpage frei).
2. Beim DNS-Anbieter von `edvanceacademy.de` den von Vercel angezeigten Eintrag setzen
   — i.d.R. `CNAME  studio  →  cname.vercel-dns.com`.
3. HTTPS richtet Vercel automatisch ein.

## 4. Lena als Admin-User anlegen

QS-Schreiben braucht `role = 'admin'` (RLS-Policy `screening_items_admin_all`).

1. Supabase Dashboard → **Authentication → Users → Add user**
   (E-Mail + Passwort, „Auto Confirm" aktivieren).
2. Die **User-UUID** aus der Liste kopieren, dann im **SQL Editor**:

   ```sql
   insert into public.profiles (id, email, role, full_name)
   values ('<USER_UUID>', 'lena@edvanceacademy.de', 'admin', 'Lena')
   on conflict (id) do update set role = 'admin';
   ```

3. Fertig: Lena öffnet `https://studio.edvanceacademy.de`, loggt sich ein → `/admin/qs`.

> ⚠️ `admin` = volle Rechte (sieht/ändert alles). Wenn Lena später auf „nur Inhalte/QS"
> beschränkt sein soll, bauen wir eine eigene Rolle `content`/`editor` + enge RLS
> (Foundation-Migration, mit Rasit).

## 5. Pre-Launch privat halten (optional)

`/admin/qs` ist bereits admin-geschützt. Wer auch Login/Landing vor dem Launch
verstecken will: Vercel → Settings → **Deployment Protection** →
*Password Protection* oder *Vercel Authentication* (Pro-Feature).

## Troubleshooting

- **Log zeigt `> vite` / „Local: http://localhost:5173" statt eines Builds:**
  Die Build-Command ist falsch (es läuft `npm run dev`). Fix: Settings →
  Build & Development Settings → Framework **Vite**, **Build Command = `npm run build`**,
  Output **`dist`**. Auf `dev` erzwingt `vercel.json` das ohnehin.
- **Deploy zeigt neue Features (z.B. `/admin/qs`) nicht:** Vercel baut den falschen
  Branch. Production Branch auf `dev` setzen (s.o.) oder `dev → main` mergen.
- **404 bei direktem Aufruf von `/admin/qs`:** SPA-Rewrite fehlt — `vercel.json`
  muss auf dem gebauten Branch liegen (ist auf `dev`).

## Was ich (Repo) vs. du (Dashboard) machst

- **Repo (erledigt):** `vercel.json` (SPA-Routing), diese Anleitung.
- **Dashboard/DNS (du):** Vercel-Projekt + GitHub verbinden, Env-Vars, Domain/DNS,
  Lenas Admin-User.
