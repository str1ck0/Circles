# Circles — Implementation Plan

Working document for the portfolio push. Updated 2026-09-14.

**Goal:** a polished, production-quality social app worth showing as a portfolio piece —
correct authorization, real product features, professional UI. **Non-goals:** migrating off
Rails/Hotwire/Bootstrap, swapping Postgres, replacing Devise.

> Architecture, conventions and the gotchas that bite (test env, libsass, icon alignment,
> deploy verification) live in **`CLAUDE.md`** — read that first. This file is the product
> and roadmap record: what was decided, what shipped, what's left.

---

## Where things stand

**Live at https://circles-rpke.onrender.com** (Render + Neon + Upstash). Merging to
`master` auto-deploys. Demo login `benten@gmail.com` / `password`.

**108 tests, green.** Coverage is concentrated where the risk is: policies, every guarded
controller path, channels, and the payment split.

The app is feature-complete against the plan below. Everything from the original audit is
closed, all six phases shipped, and the UI has been rebuilt end to end.

---

## Product decisions (agreed 2026-09-07)

These shaped the whole build; changing them means revisiting a lot.

- **Circles are public clubs or private groups.** `private = false` → browsable by every
  signed-in user and joinable in one click. `private = true` → visible only to members,
  who get in by invitation (in-app or link).
- **Events inherit visibility from their circles.** An event is visible to its guest list
  and, unless `events.private`, to members of any attached circle. Attaching a circle puts
  its members on the guest list as `invited`.
- **The guest list is the access list.** Any row on `user_events` — whatever the RSVP
  status, including `declined` — grants chat, playlists and Splitty access.
- **Visual direction:** evolve the original identity (dark ground, orbit motif, neon ring
  colours, orange accent) rather than restyling from scratch. Bootstrap 5 + SCSS stays.

---

## What shipped

| # | PR | What |
|---|---|---|
| 1 | [#3](https://github.com/str1ck0/Circles/pull/3) | **Authorization foundation** — Pundit policies, cable identification, `private` made real, public-circle discovery, plus the three correctness bugs from the audit |
| 2 | [#4](https://github.com/str1ck0/Circles/pull/4) | **RSVP states** — invited / going / maybe / declined, live counts, guest list grouped by answer |
| 3 | [#5](https://github.com/str1ck0/Circles/pull/5) | **Invitations + notifications** — personal invites and 7-day links, activity feed, unread badge |
| 4 | [#6](https://github.com/str1ck0/Circles/pull/6) | **Profiles + people directory** — public profiles, bio, handle, name/username search |
| 5 | [#7](https://github.com/str1ck0/Circles/pull/7) [#8](https://github.com/str1ck0/Circles/pull/8) [#9](https://github.com/str1ck0/Circles/pull/9) [#10](https://github.com/str1ck0/Circles/pull/10) | **UI revamp** — design tokens and app shell, then circle, event, and dashboard/profile/forms |
| 6 | [#11](https://github.com/str1ck0/Circles/pull/11) | **Concern extraction + cleanup** — the circle/event mirror collapsed into shared concerns and base classes, one chat Stimulus controller, README rewritten |
| — | [#12](https://github.com/str1ck0/Circles/pull/12) [#13](https://github.com/str1ck0/Circles/pull/13) | Invite-on-create for new circles, chat/sidebar alignment, mobile pass |
| — | [#14](https://github.com/str1ck0/Circles/pull/14) | **Event editing and deletion** (+ the Splitty cascade fix that made deletion possible) |
| — | [#15](https://github.com/str1ck0/Circles/pull/15) | **Leave a circle / owner removes members** |
| — | [#16](https://github.com/str1ck0/Circles/pull/16) [#17](https://github.com/str1ck0/Circles/pull/17) | Sidebar and app-wide icon alignment, circle rail sizing, label capitalisation |

The audit that drove phases 1–6:
[findings report](https://claude.ai/code/artifact/65ee6d6f-ba2f-483d-94df-a0d33c79dfed)
(9 critical, 3 high, 1 medium, 3 low — all closed).

---

## What's next

Nothing is in flight. These are the open threads, roughly in order of value:

**1. Transfer circle ownership.** The most load-bearing gap. Today an owner can't leave a
circle — `CirclePolicy#leave?` refuses, because leaving would orphan it — so their only
exit is deleting the circle out from under everyone. Let an owner hand over to another
member, then allow them to leave. Needs: a policy action, a control in the members panel,
and a notification to the new owner. See the membership rules in `CLAUDE.md`.

**2. Pagination.** Two unbounded queries: circle/event chat history loads every message,
and the people directory caps at 30 with no way to page. The home feed is already capped at
30 upcoming events. Chat wants "load older" rather than numbered pages.

**3. System tests for chat and RSVP.** Capybara and selenium-webdriver are already in the
Gemfile and unused. The suite covers policies and controllers well, but nothing exercises
the Action Cable round trip or the RSVP Stimulus controller in a real browser — both were
verified by hand each time instead.

**Smaller things:** the event-hero meta icons sit ~0.3px off (below perception, left
deliberately); `docs/screenshots/` is empty and the README has no images; there's no CI —
tests run locally only.

---

## Notes for whoever picks this up

- **Work in a branch, PR, then merge** — merging deploys to production. As of 2026-09-11
  the owner wants to be **asked before anything is committed or pushed**.
- **Verify in the browser, not just the suite.** Several bugs here (chat rendering, icon
  alignment, the RSVP control) only showed up in a real page. `CLAUDE.md` has the icon
  audit script and the deploy-verification snippet.
- **Local seed dates are relative to seed time**, so a database seeded a while ago shows
  everything under "Past". `bin/rails db:seed` to refresh.
