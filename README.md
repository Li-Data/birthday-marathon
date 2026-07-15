# Birthday Marathon — setup

Static site (GitHub Pages) + Supabase. ~15 minutes to live.
Point the flyer's QR code at the deployed index.html URL.

Files: `index.html` (registration), `dashboard.html` (Race Control),
`waiver.html` (printable waiver for plus ones / paper backup), `setup.sql`.

## 1. Supabase (fresh free project, not the Nectar one)

1. Create a new project at supabase.com.
2. Open `setup.sql`, replace `YOUR_EMAIL_HERE` (2 places) with the email you'll
   use for the dashboard, and run it in the SQL editor.
3. Auth settings:
   - Easiest order: leave signups on, log into the dashboard once with your
     email (this creates your user), then disable new signups under
     Authentication → Sign In / Up. RLS only allows your email anyway.
   - Authentication → URL Configuration: add your GitHub Pages dashboard URL
     to redirect URLs (e.g. `https://<you>.github.io/birthday-marathon/dashboard.html`).

## 2. Configure the pages

Fill in the `CONFIG` block at the top of `index.html` and `dashboard.html`:
`SUPABASE_URL`, `SUPABASE_ANON_KEY` (Settings → API — the anon key is safe to
expose; RLS means it can only call `register_guest`), and your WhatsApp number
in `index.html`.

## 3. Photos (hero slideshow)

The hero runs a slow crossfade slideshow of your race photos. Your first
marathon photo is already in `photos/race-1.jpg`. To add more:

1. Drop them into `photos/` (landscape or portrait both work; they're
   cropped to cover). Compress them first — aim for under ~400KB each
   (squoosh.app does this in seconds) or mobile load will crawl.
2. List them in the `PHOTOS` array in the CONFIG block of `index.html`,
   best photo first. One photo = static hero, no crossfade.

## 4. Deploy

New repo, push the three HTML files plus the `photos/` folder, enable
GitHub Pages. Share the index URL and regenerate the flyer QR to point at it.

## What registration captures

Name, phone, date of birth, category (5K / 10K / spectator), shuttle,
plus one (full name + age required if yes), emergency contact (name + phone),
and waiver acceptance. The waiver is embedded in the form, adapted from the
Backyard Ultra release to cover this event's full activity list (runs,
swimming, archery, zipline, game viewing). Acceptance is enforced twice:
the form won't submit without the checkbox, and the RPC rejects any call
without it. The acceptance timestamp is stored with each registration.

Note: the digital acceptance records name, DOB, and timestamp as the
signature. Plus ones can't accept through someone else's registration, so
they sign the printable `waiver.html` at race pack collection — print a
stack the night before. Worth a quick legal sanity check if you want the
waivers to carry real weight; I'm not a lawyer and enforceability of
click-through waivers varies.

## Race day workflow (race pack collection, from 06:30ish)

1. Open the dashboard on your phone, keep the "Packs to hand out" tile in view.
2. Guest arrives with labelled gift → search their name or bib number →
   tap "Gift in → pack" → hand them their race pack.
3. Plus ones sign the paper waiver before getting their pack.
4. Export the CSV the night before as a paper backup (it includes emergency
   contacts — useful to have offline given the zipline and swimming).
