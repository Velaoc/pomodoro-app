# Demo data for the Pomodoro demo deck.
#
# A demo user with a handful of completed focus/break sessions spread over the
# last few days so the history view and per-day focus totals show real data on
# first load. Idempotent: re-running seeds never duplicates the user.
#
# The demo user is explicitly a preview account. Before a production launch the
# operator should remove this file's user and replace the demo password with a
# real onboarding flow. Seeding is best-effort: a failure here (for example the
# demo address being refused by the disposable-domain validator) prints a
# warning and never blocks the app from booting.

DEMO_EMAIL = 'demo@pomodoro.demo'
DEMO_PASSWORD = 'demo-pomodoro-1234' # 12+ chars, satisfies Devise minimum

begin
  demo_user = User.find_or_initialize_by(email: DEMO_EMAIL)
  if demo_user.new_record?
    demo_user.password = DEMO_PASSWORD
    demo_user.password_confirmation = DEMO_PASSWORD
    demo_user.legal_assent = '1'
    demo_user.save!
    puts "Created demo user #{DEMO_EMAIL}"
  end

  if demo_user.timer_sessions.none?
    now = Time.current
    plans = [
      { days_ago: 0, start_hour: 9, count: 2 },
      { days_ago: 1, start_hour: 14, count: 3 },
      { days_ago: 3, start_hour: 10, count: 4 },
      { days_ago: 5, start_hour: 11, count: 1 }
    ]

    plans.each do |plan|
      day = (now - plan[:days_ago].days).beginning_of_day
      cursor = day + plan[:start_hour].hours
      plan[:count].times do |i|
        focus_start = cursor
        focus_end = focus_start + 25.minutes
        TimerSession.create!(
          user: demo_user,
          kind: 'focus',
          duration_minutes: 25,
          started_at: focus_start,
          completed_at: focus_end
        )
        cursor = focus_end
        next unless i < plan[:count] - 1

        break_start = cursor
        break_end = break_start + 5.minutes
        TimerSession.create!(
          user: demo_user,
          kind: 'short_break',
          duration_minutes: 5,
          started_at: break_start,
          completed_at: break_end
        )
        cursor = break_end
      end
    end

    TimerSession.create!(
      user: demo_user,
      kind: 'long_break',
      duration_minutes: 15,
      started_at: now - 15.minutes,
      completed_at: now
    )

    puts "Seeded #{demo_user.timer_sessions.count} timer sessions for #{DEMO_EMAIL}"
  end

  puts "Seed complete. Demo login: #{DEMO_EMAIL} / #{DEMO_PASSWORD}"
rescue StandardError => e
  warn "Demo seed skipped: #{e.class}: #{e.message}"
end
