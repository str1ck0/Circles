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

**UI system.** Design tokens live in `app/assets/stylesheets/config/` (`_colors.scss` →
SCSS vars, `_tokens.scss` → CSS custom properties, `_bootstrap_variables.scss` → Bootstrap
overrides so forms/modals are dark by default). The signed-in layout is the shell in
`components/_shell.scss` + `shared/_sidebar.html.erb` (sidebar on desktop, top bar under
992px); pages wrap content in `.page` / `.page-header`. Buttons are `.btn-accent` (the one
primary action) and `.btn-ghost`; avatars are `.ring-avatar` with `style="--ring: #hex"`.
Pages not yet rebuilt (circle, event, dashboard) rely on the "compatibility" block at the
bottom of `_shell.scss` — delete their entries as each page is revamped.

**Circles and events mirror each other, and the shared behaviour is extracted.** Messages
and playlists exist twice (`circle_messages`/`event_messages`, `circle_playlists`/
`event_playlists`) but the logic lives once: `ChatMessage` and `SpotifyEmbed` model
concerns, `ChatroomChannel` (channels declare `chatroom_class`), `ChatMessagesController`
and `PlaylistsController` bases (subclasses only name the parent, association, channel and
param key), the `shared/_chat_message` partial and a single `chatroom-subscription`
Stimulus controller that takes the channel name as a value. Change the base, not the twins.

**Authorization is Pundit, and there are only two policies that matter.** `CirclePolicy`
and `EventPolicy` (`app/policies/`) carry every rule; the join-table controllers
(messages, playlists, user_circles, user_events, circle_events, payments) authorize
against the parent — `authorize @circle, :chat?` — rather than having policies of their
own. `ApplicationController` runs `verify_authorized` after every non-Devise action, so a
new action that forgets to `authorize` fails loudly. Chat channels identify
`current_user` from Warden in `ApplicationCable::Connection` and `reject` unless the
policy's `chat?` allows. Semantics: `private: false` circles are public clubs (visible to
all, one-click join); private ones are members-only. An event is visible to attendees and,
unless private, to members of its attached circles. "Attendee" means *any* row on
`user_events` regardless of its RSVP `status` (`invited`/`going`/`maybe`/`declined`) —
the guest list is the access list.

**Invitations and notifications.** Joining a private circle happens through an
`Invitation` — personal (one-shot, accept/decline from `/notifications`) or link
(`/invites/:token`, open for 7 days, reusable). `UserCirclesController` is self-join for
public circles only. Notifications are only ever created via `Notification.notify(...)`,
which drops self-notifications; anything that can be a `notifiable` must declare
`has_many :notifications, as: :notifiable, dependent: :destroy` or the polymorphic
`belongs_to` dangles after the subject is deleted.

**Membership changes have rules worth knowing before you touch them.** A member leaves via
`UserCirclesController#destroy`; the owner uses the same action to remove someone else
(`CirclePolicy#leave?` vs `#remove_member?`). The **owner can't leave** — they'd orphan the
circle, so they delete it instead; transferring ownership doesn't exist yet and is the
obvious way to lift that restriction. The **last member out destroys the circle**, because
an empty private circle is unreachable for everyone.

**Deleting records that touch the Splitty needs the cascade.** `payments` and `splittees`
both hang off `user_events` with `NOT NULL` foreign keys, so `UserEvent` declares
`dependent: :destroy` for both and `Payment` does for `splittees`. Without those, deleting
an event (or a guest) raises a FK violation — it was latent until event deletion shipped.

**Bill splitting lives on the join table, not the user.** `balance` is a column on
`user_events`, so it is per-event, not a global wallet. The split arithmetic is in
`PaymentsController#create`, wrapped in a transaction; the payer absorbs the integer
remainder so balance changes always sum to zero.

**Real-time chat** uses the in-process `async` adapter in development, so it works with no
Redis running. Production needs `REDIS_URL` *and* `APP_HOST` — the latter feeds
`config.action_cable.allowed_request_origins` in `config/environments/production.rb`, and
chat silently fails to connect without it.

## Tests

`bin/rails test` should be green. Coverage is concentrated where the risk is: policy
tests, controller tests for every guarded path, channel tests, and the payment split.
Build records with the helpers in `test/test_helper.rb` (`create_user`, `create_circle`,
`create_event`) — circles need a photo *and* banner attached to be valid, and the helpers
handle that with `test/fixtures/files/avatar.png`. Geocoder is stubbed globally.

Three deliberate settings in `config/environments/test.rb`, each there because of a real
failure:

- `config.active_job.queue_adapter = :test` — with the default `:async` adapter, Active
  Storage's analyze jobs run on background threads sharing the transactional test
  connection: attachments intermittently vanished mid-test and the suite sometimes hung
  at exit.
- `config.assets.css_compressor = nil` — mirrors production; without it
  sassc-rails adds a compressor pass that can't parse tom-select's `max(var(--x), …)`.
- **If view tests fail with `AssetNotPrecompiledError` for `application.css`, the
  Sprockets cache is poisoned** — `rm -rf tmp/cache/assets` and rerun. It happens after any
  failed CSS compile (a Sass error in a partial) and after building a production-mode
  Sprockets environment locally. Fix the CSS first, then clear the cache.
- **libsass (sassc) evaluates CSS `min()`/`max()` as Sass functions** and can't mix units
  or `var()`/`calc()` inside them. Use `width` + `max-width`, or media queries, instead.
  `clamp()` and `minmax()` are fine (not Sass functions).

## Icon alignment

Font Awesome glyphs and Josefin Sans don't centre alike: the label's ink rides high in its
line box (cap height above the baseline, unused descender space below) while a glyph fills
its own, so a centred flex row lines up the *boxes* but not what you see. Every
icon-beside-text context therefore carries a small measured `top` nudge — negative in flex
rows (`%btn-base`, `.btn-sm`, `.chip`, `.dash-link`, `.sidebar-actions`), positive in inline
ones (`.event-card-meta`, `.map-caption`, `.circle-card-body p`, `.invite-landing-meta`),
because the two regimes err in opposite directions. The values differ per context and don't
scale linearly with font-size, so **measure, don't guess** — paste this in the browser
console to audit a page (it reports icon ink centre minus label cap-height centre; aim for
under ~0.3px):

```js
const c = document.createElement('canvas').getContext('2d');
document.querySelectorAll('a,button,span,p,li,div,h5,h2,dd').forEach(el => {
  const i = el.querySelector(':scope > i'); if (!i) return;
  const t = [...el.childNodes].find(n => n.nodeType === 3 && n.textContent.trim()); if (!t) return;
  const ir = i.getBoundingClientRect(); if (!ir.width) return;
  const ics = getComputedStyle(i), ip = getComputedStyle(i, '::before');
  c.font = `${ip.fontWeight} ${ics.fontSize} ${ip.fontFamily}`;
  const im = c.measureText(ip.content.slice(1, -1));
  const iC = ir.top + (ir.height - (im.fontBoundingBoxAscent + im.fontBoundingBoxDescent)) / 2 +
             im.fontBoundingBoxAscent - (im.actualBoundingBoxAscent - im.actualBoundingBoxDescent) / 2;
  const r = document.createRange(); r.selectNodeContents(t);
  const tr = r.getBoundingClientRect(), tcs = getComputedStyle(el);
  if (tr.height > parseFloat(tcs.fontSize) * 1.8) return; // skip wrapped text
  c.font = `${tcs.fontWeight} ${tcs.fontSize} ${tcs.fontFamily}`;
  const tm = c.measureText('H');
  const tCap = tr.top + (tr.height - (tm.fontBoundingBoxAscent + tm.fontBoundingBoxDescent)) / 2 +
               tm.fontBoundingBoxAscent - tm.actualBoundingBoxAscent / 2;
  console.log(el.className || el.tagName, (iC - tCap).toFixed(2) + 'px');
});
```

Judge against the label's **cap-height** centre, not its ink centre — a label with a
descender ("View profile") has a lower ink centre than one without ("Invite friends"), so
matching ink makes the icon jump around between buttons.

Routes are deliberately trimmed to implemented actions only, so scaffold-style tests and
`link_to` helpers for unimplemented CRUD will not resolve.

## Deployment

**Live at https://circles-rpke.onrender.com** — Render (web, free tier, Frankfurt) with
Neon (Postgres) and Upstash (Redis), configured by `render.yaml` + `bin/render-build.sh`.
Merging to `master` auto-deploys; a build takes about 90 seconds. The free dyno sleeps when
idle, so the first request after a quiet spell takes ~30s.

The build script runs `db:prepare` then seeds **only if `User.count.zero?`**, so redeploys
preserve visitor data — which means **migrations must carry their own defaults and
backfills**, since the seeds won't re-run to fix anything up.

`APP_HOST` is set to the Render hostname and feeds
`config.action_cable.allowed_request_origins`. Without it the site loads fine and chat
silently fails to connect, with nothing obvious in the logs.

To confirm a deploy landed, grep the live CSS bundle for a selector you just added rather
than trusting a page screenshot:

```bash
css=$(curl -s https://circles-rpke.onrender.com/ | grep -o '/assets/application-[a-f0-9]*\.css' | head -1)
curl -s "https://circles-rpke.onrender.com$css" | grep -c "your-new-class"
```
