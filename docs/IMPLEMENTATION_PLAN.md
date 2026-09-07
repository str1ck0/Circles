# Circles — Implementation Plan

Working document for the portfolio push. Updated 2026-09-07.

**Goal:** turn Circles into a polished, production-quality social app worth showing as a
portfolio piece: correct authorization, real product features, and a professional UI —
without rebuilding the stack.

**Non-goals:** migrating off Rails/Hotwire/Bootstrap, swapping Postgres, replacing Devise.

---

## Status at a glance

| Area | State |
|---|---|
| Core features | ✅ Done, verified in browser |
| Deploy | ✅ **Live at https://circles-rpke.onrender.com** (Render + Neon + Upstash) |
| Audit | ✅ [Findings report](https://claude.ai/code/artifact/65ee6d6f-ba2f-483d-94df-a0d33c79dfed) — 9 critical, 3 high, 1 medium, 3 low |
| Phase 1 — Authorization foundation | 🔄 In progress |
| Phase 2 — RSVP states | ⬜ |
| Phase 3 — Invitations + notifications | ⬜ |
| Phase 4 — Profiles + user search | ⬜ |
| Phase 5 — UI revamp | ⬜ |
| Phase 6 — Concern extraction + cleanup | ⬜ |

---

## Product decisions (agreed 2026-09-07)

- **Circles are public clubs or private groups.** `circles.private = false` → browsable by
  every signed-in user and joinable with one click. `private = true` → visible only to
  members; people get in by being invited by an existing member, either in-app (user
  search) or via an invite link.
- **Events inherit from their circles.** An event is visible to its attendees and, unless
  `events.private`, to members of any circle it's attached to. Attaching a circle to an
  event enrols that circle's members.
- **Visual direction:** evolve the existing identity — dark ground, orbit motif, neon ring
  colours — rebuilt to a professional standard. Bootstrap 5 + SCSS stays.
- **Features in scope:** RSVP states (going / maybe / can't), in-app + link invitations,
  public profiles with name search, activity feed / notifications with unread badges.

---

## Phase 1 — Authorization foundation (`fix/authorization-foundation`)

Closes every AUTH finding and the three BUG findings from the audit in one coherent PR,
and ships public-circle discovery at the same time so new signups have a way in (the
`User#friends` cold-start problem described in the audit).

- Add **Pundit**. `CirclePolicy` and `EventPolicy` carry every rule; join-table controllers
  authorize against the parent (`authorize @circle, :post_message?`), so there are only
  two policies to reason about.
- `ApplicationCable::Connection` identifies `current_user` via Warden; both chat channels
  `reject` unless the policy allows `show?`.
- `PagesController#home` uses `policy_scope` and gains a **Discover** list of public
  circles the user hasn't joined. Signed-out visitors see public circles and their public
  events only.
- Make `private` real: migrations default it to `false`/`NOT NULL` on both tables.
- `UserEvent` gets a uniqueness validation (attaching a circle twice currently creates
  duplicate rows).
- `PaymentsController#create`: transaction, guard `save`, validations on `Payment`,
  remainder goes to the payer so balance deltas always sum to zero.
- `UserEventsController#create`: fix the `respond_to` `NameError`.
- Dashboard: scope another user's circles to what the viewer may see, guard the
  zero-circles crash, remove the hard-coded fake invites/notifications.
- Tests: policy tests, controller tests for each guarded path, channel connection test,
  payment split test. Replace the stale `user_circles_controller_test.rb` scaffold.
- Sticky footer on short pages (login/signup).

## Phase 2 — RSVP states

`user_events.status` enum: `invited`, `going`, `maybe`, `declined` (default `invited`).
Attaching a circle enrols members as `invited`; cards show the `going` count; the event
page gets a three-state control replacing the binary "Attend". `attend_controller.js`
becomes an RSVP controller.

## Phase 3 — Invitations + notifications

Coupled because an invite *is* a notification.

- `Invitation` (circle, inviter, invitee nullable, token, expires_at, accepted_at).
  In-app: member searches users → invitation → invitee accepts. Link: `/invites/:token`,
  accepted by whoever is signed in. Replaces the direct "add member" from Phase 1.
- `Notification` (recipient, actor, notifiable polymorphic, kind, read_at). Created for:
  invited to a circle, new event in your circle, RSVP on your event. Unread badge in the
  sidebar, notifications page, mark-read on view.

## Phase 4 — Profiles + user search

`users#show` public profile (avatar, name, username, bio, shared circles), `users#index`
name/username search (also feeds the invite flow). Adds `users.bio`. Replaces the current
`dashboard/:id` for other people; own dashboard stays.

## Phase 5 — UI revamp

Screen by screen, each its own PR: design tokens + layout shell first (sidebar, main,
responsive breakpoints, sticky footer), then Devise pages, home/discover, circle page,
event page, profile/dashboard, notifications. Rewrite SCSS cleanly on top of Bootstrap;
keep the orbit/ring motif.

## Phase 6 — Concern extraction + cleanup

Only once Phases 1–3 have settled the behaviour on both sides of the mirror:

- Shared concern for membership checks, message posting, playlist creation (audit DUP-01).
- Delete `app/views/shared/_navbar.html.erb` (dead, Le Wagon-branded).
- Move the favicon into the repo's assets.
- Paginate/limit the home feed.

---

## Context worth not re-deriving

- **The mirror pattern.** Circles and events each have their own messages, channel,
  playlists and Stimulus subscription controller. Fixes on one side almost always need the
  twin on the other.
- **`balance` is on `user_events`, not `users`** — bill splitting is scoped per event, not a
  global wallet.
- **`Circle#owner` was added by later migration** and is `optional: true`.
- **Chat works locally with no Redis** thanks to the `async` adapter, so "it works on my
  machine" tells you nothing about production. Production needs `REDIS_URL` + `APP_HOST`
  (both set on Render).
- **Routes are trimmed to implemented actions**, so missing URL helpers are usually
  intentional, not a bug.
- **Production seeds run only when `User.count.zero?`** (`bin/render-build.sh`), so
  migrations must carry defaults/backfills for existing rows.
- **Repo is `str1ck0/Circles`, default branch `master`.** PR-per-phase; doc-only fixes may
  go straight to master.
