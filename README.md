<!-- foundation:identity -->
# Pomodoro

A focused Pomodoro timer app: 25-minute focus sessions alternating with 5-minute short breaks and a 15-minute long break every four sessions, with a session history for signed-in users.

- Site: https://pomodoro-app.api.holode.xyz
- Support: support@pomodoro-app.api.holode.xyz
<!-- /foundation:identity -->

## What this is

A focused Pomodoro timer app: 25-minute focus sessions alternating with 5-minute short breaks and a 15-minute long break every four sessions, with a session history for signed-in users.

## Who it is for

- Guest (uses the timer without an account)
- Signed-in user (timer plus persisted session history)

## Main features

- **Run a focus cycle** — Start/pause/reset the countdown; timer auto-advances focus to short break to focus, and to a long break every four sessions, beeping on completion; completed sessions are saved for signed-in users.
- **Review history** — Signed-in user browses completed sessions with per-day focus totals.

## Core entities

- TimerSession

## Run locally

```bash
bundle install
bin/rails db:prepare
bin/dev
```

Requires Ruby, PostgreSQL, and the usual Rails toolchain. See `bin/setup` if present.

## Demo

A demo user with several completed focus/break sessions spread over recent days so the history view and day totals show real data.

## Deploy notes

Production `config.hosts` is derived from `domain` in `config/foundation.yml`. Keep that value aligned with the real host or every request will 403.
