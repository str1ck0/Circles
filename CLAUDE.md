# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup                  # install deps, prepare DB
bin/dev                    # foreman: Rails on :3000 + `yarn build --watch`
bin/rails server -p 3001   # server only (use another port if 3000 is taken)
yarn build                 # one-shot webpack build
bin/rails db:seed          # rebuild demo data (destructive — see db/seeds.rb)
bin/rails test             # full suite
bin/rails test test/models/user_test.rb        # single file
bin/rails test test/models/user_test.rb:12     # single test by line
```

There is no linter or formatter configured — don't invent one.

`bin/dev` needs both processes. JS is bundled by **webpack via jsbundling-rails**, not
importmap, so changes under `app/javascript/` are invisible until `yarn build` runs.

## Environment

`.env` is gitignored and holds `CLOUDINARY_URL` and `MAPBOX_API_KEY`. Without them the app
still boots: Geocoder falls back from `:mapbox` to `:nominatim`
(`config/initializers/geocoder.rb`), and dev ActiveStorage is `:local` regardless. Production
uses `:cloudinary`.

Demo login is `benten@gmail.com` / `password` — every seeded user shares that password.

## Architecture

Rails 7.0 / Ruby 3.1.2 / PostgreSQL, Hotwire (Turbo + Stimulus), Devise for auth.

**The domain is join-table heavy, and that's the main thing to internalise.** Users, circles
and events are all many-to-many through explicit models that carry their own behaviour:

```
User ──user_circles──> Circle ──circle_events──> Event <──user_events── User
                                                   │
                                              payments ──splittees──> user_events
```

`Circle` also has an `owner` (`belongs_to :owner, class_name: "User", optional: true`)
separate from its members — added later, so older code may assume membership implies
ownership.

**Circles and events are near-perfect mirrors of each other.** Each has its own messages
model, Action Cable channel, Stimulus subscription controller, and playlists model
(`circle_messages`/`event_messages`, `CircleChatroomChannel`/`EventChatroomChannel`,
`circle_playlists`/`event_playlists`). A change to one side almost always needs the same
change on the other — grep for the `circle_` name and its `event_` twin before assuming a
fix is complete.

**Bill splitting lives on the join table, not the user.** `balance` is a column on
`user_events`, so it is per-event, not a global wallet. The split arithmetic is in
`PaymentsController#create`, not in `Payment` — the model is associations only.

**Real-time chat** uses the in-process `async` adapter in development, so it works with no
Redis running. Production needs `REDIS_URL` *and* `APP_HOST` — the latter feeds
`config.action_cable.allowed_request_origins` in `config/environments/production.rb`, and
chat silently fails to connect without it.

## Tests

The suite is thin and mostly unwritten. Only `test/models/user_test.rb`,
`circle_playlist_test.rb` and `event_playlist_test.rb` contain real assertions; every other
file under `test/` is an empty generated scaffold. `bin/rails test` currently reports
**1 error** — `test/controllers/user_circles_controller_test.rb` is a stale scaffold calling
a `user_circles_create_url` helper that doesn't exist. That failure is pre-existing and
unrelated to any change you make.

Routes are deliberately trimmed to implemented actions only, so scaffold-style tests and
`link_to` helpers for unimplemented CRUD will not resolve.

## Known rough edges

- `UserEventsController#create` — the `else` branch calls `format.html` outside any
  `respond_to` block, raising `NameError` whenever the save fails.
- `PaymentsController#create` — `payment.amount` is an integer column and the split uses
  integer division, so remainders vanish and balances drift by a few units.

## Deployment

Not yet deployed. `render.yaml` + `bin/render-build.sh` target Render (web) with Neon
(Postgres) and Upstash (Redis). The build script runs `db:prepare` then seeds **only if
`User.count.zero?`**, so redeploys don't wipe visitor data. See
`docs/IMPLEMENTATION_PLAN.md` for the full sequence and current status.
