<div align="center">

# ◎ Circles

**Plan events with the people who matter — in circles.**

Circles is a social event-planning web app. You form **circles** with your
friends, create **events** inside them, chat in real time, split the bill, share
Spotify playlists, and see everything on a map.

<!-- Replace with your live URL once deployed -->
🔗 **[Live demo](https://circles.onrender.com)** &nbsp;·&nbsp; Log in with `benten@gmail.com` / `password`

![Ruby](https://img.shields.io/badge/Ruby-3.1.2-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-7.0-D30001?logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-5cb85c)

</div>

---

## Features

| | |
|---|---|
| 👥 **Circles** | Create private groups of friends, each with its own banner, colour and members. |
| 📅 **Events** | Plan events inside a circle — with dates, a location, a photo gallery and attendees. |
| 💬 **Real-time chat** | Live group chat in every circle and event, powered by Action Cable (WebSockets). |
| 🗺️ **Maps** | Event locations are geocoded and shown on an interactive Mapbox map. |
| 💸 **Bill splitting** | "Splitty" tracks who paid what and settles balances across attendees. |
| 🎧 **Playlists** | Embed Spotify playlists on any circle or event. |
| 🖼️ **Memories** | Photo carousels for each event. |
| 🔐 **Auth** | Email/password accounts via Devise. |

<!--
## Screenshots
Drop images into docs/screenshots/ and they'll render here:

![Home](docs/screenshots/home.png)
![Circle with live chat](docs/screenshots/circle.png)
![Event with map and bill-splitting](docs/screenshots/event.png)
-->

## Tech stack

- **Backend:** Ruby 3.1.2, Ruby on Rails 7.0, PostgreSQL
- **Front-end:** Hotwire (Turbo + Stimulus), Bootstrap 5, SCSS, bundled with Webpack (`jsbundling-rails`)
- **Real-time:** Action Cable over Redis
- **Services:** Cloudinary (image storage), Mapbox + `geocoder` (maps & geocoding)
- **Auth:** Devise

## Architecture at a glance

Users join **Circles** (via `UserCircle`), which contain **Events** (via `CircleEvent`).
Users attend events (via `UserEvent`). Chat lives in `CircleMessage` / `EventMessage`
and is broadcast over dedicated Action Cable channels. `Payment` and `Splittee`
model the bill-splitting; `CirclePlaylist` / `EventPlaylist` hold Spotify embeds.

## Getting started

### Prerequisites

- Ruby 3.1.2
- PostgreSQL
- Redis (for Action Cable)
- Node.js + Yarn

### Setup

```bash
# 1. Install dependencies
bundle install
yarn install

# 2. Configure environment variables
cp .env.example .env
#   then fill in CLOUDINARY_URL and MAPBOX_API_KEY (see .env.example)

# 3. Set up the database
bin/rails db:create db:migrate db:seed

# 4. Run the app (starts Rails + the JS build watcher)
bin/dev
```

Visit <http://localhost:3000> and log in with the seeded account:
**`benten@gmail.com` / `password`**.

### Environment variables

| Variable | Purpose |
|---|---|
| `CLOUDINARY_URL` | Image hosting — `cloudinary://<key>:<secret>@<cloud_name>` |
| `MAPBOX_API_KEY` | Maps & geocoding on event pages |

## Deployment

Circles runs on a **fully free** stack:

- **Web:** [Render](https://render.com) (free web service) — see `render.yaml`
- **Database:** [Neon](https://neon.tech) (free Postgres) → `DATABASE_URL`
- **Redis:** [Upstash](https://upstash.com) (free) → `REDIS_URL` (required for chat)
- **Images:** [Cloudinary](https://cloudinary.com) (free) → `CLOUDINARY_URL`

The `render.yaml` blueprint and `bin/render-build.sh` build script handle install,
asset compilation, migration and first-run seeding automatically.

## Tests

```bash
bin/rails test
```

## Credits

Originally built as a group project at [Le Wagon](https://www.lewagon.com).
