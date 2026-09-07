<div align="center">

# ◎ Circles

**Your people, in orbit.**

Private circles for your crew, open clubs for everyone else. Plan events, chat live,
split the bill — without the group-chat chaos.

🔗 **[Live demo](https://circles-rpke.onrender.com)** &nbsp;·&nbsp; log in with `benten@gmail.com` / `password`

![Ruby](https://img.shields.io/badge/Ruby-3.1.2-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-7.0-D30001?logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-5cb85c)
![Tests](https://img.shields.io/badge/tests-minitest-informational)

</div>

> The demo runs on Render's free tier, so the first load after a quiet spell takes
> ~30 seconds while the dyno wakes up.

---

## What it does

| | |
|---|---|
| 👥 **Circles** | Open clubs anyone can join, or private circles that are invite-only. Each has a photo, banner and its own ring colour. |
| ✉️ **Invitations** | Members invite people in-app (with a notification to accept or decline) or share a 7-day invite link. |
| 📅 **Events** | Plan events for one or more circles — everyone in those circles lands on the guest list. Dates, location, photos. |
| ✅ **RSVPs** | Going / Maybe / Can't go, with live counts and a guest list grouped by answer. |
| 💬 **Real-time chat** | A chat room in every circle and event over Action Cable — members only. |
| 🔔 **Notifications** | Invites, new events, RSVPs on your events, people joining your circle. Unread badge in the sidebar. |
| 🗺️ **Maps** | Locations are geocoded and shown on a Mapbox map. |
| 💸 **Splitty** | Bill splitting that keeps every balance honest — the payer absorbs the rounding, so the books always sum to zero. |
| 🎧 **Playlists** | Spotify embeds on circles and events. |
| 🪪 **Profiles** | Public profiles with bio and handle, and a people directory with search. |

## How it's built

**Rails 7.0 · Ruby 3.1.2 · PostgreSQL · Hotwire (Turbo + Stimulus) · Bootstrap 5 + SCSS · Action Cable over Redis · Devise · Pundit**

- **Authorization is the spine.** `CirclePolicy` and `EventPolicy` hold every rule; join-table
  controllers authorize against the parent, and `verify_authorized` runs after every action so
  nothing ships unguarded. Chat channels reject anyone the policy wouldn't let in.
- **Circles and events mirror each other** (messages, channels, playlists), so the shared
  behaviour lives in concerns and base classes: `ChatMessage`, `SpotifyEmbed`,
  `ChatroomChannel`, `ChatMessagesController`, `PlaylistsController`, and one
  `chatroom-subscription` Stimulus controller for both.
- **Design system**: tokens in `app/assets/stylesheets/config/`, a persistent sidebar shell that
  collapses to a top bar on small screens, Josefin Sans + Work Sans, and the ring/orbit motif
  carried through avatars and the landing page.
- **Services**: Cloudinary (images), Mapbox + `geocoder` (maps), Redis (cable pub/sub).

## Running it locally

```bash
bin/setup                     # bundle, yarn, database
cp .env.example .env          # add CLOUDINARY_URL and MAPBOX_API_KEY (both optional locally)
bin/rails db:seed             # demo data: 61 users, 8 circles, 8 events, chat history
bin/dev                       # Rails on :3000 + the JS build watcher
```

Log in with **`benten@gmail.com` / `password`** — every seeded user shares that password.
Chat works locally with no Redis (the `async` adapter); production needs `REDIS_URL`.

```bash
bin/rails test                # policy, controller, channel and model tests
```

## Deployment

Free-tier stack, no card required: **Render** (web, `render.yaml`), **Neon** (Postgres),
**Upstash** (Redis), **Cloudinary**, **Mapbox**. `bin/render-build.sh` installs, precompiles,
migrates and seeds on first boot only. Set `APP_HOST` to the assigned hostname — it feeds
Action Cable's allowed origins, and chat silently fails without it.

## Credits

Started as a one-week group project at [Le Wagon](https://www.lewagon.com) and rebuilt
afterwards into what's here.
