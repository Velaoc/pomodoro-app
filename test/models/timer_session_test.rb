require "test_helper"

class TimerSessionTest < ActiveSupport::TestCase
  test "valid with focus kind and positive duration" do
    user = users(:one)
    session = TimerSession.new(
      user: user,
      kind: "focus",
      duration_minutes: 25,
      started_at: 25.minutes.ago,
      completed_at: Time.current
    )
    assert session.valid?
  end

  test "rejects unknown kinds" do
    user = users(:one)
    session = TimerSession.new(
      user: user,
      kind: "nap",
      duration_minutes: 25,
      started_at: 25.minutes.ago,
      completed_at: Time.current
    )
    assert_not session.valid?
  end

  test "focus_minutes_on sums focus minutes for a day" do
    user = users(:one)
    day = Date.current

    TimerSession.create!(
      user: user, kind: "focus", duration_minutes: 25,
      started_at: day.beginning_of_day + 9.hours, completed_at: day.beginning_of_day + 9.hours + 25.minutes
    )
    TimerSession.create!(
      user: user, kind: "focus", duration_minutes: 25,
      started_at: day.beginning_of_day + 14.hours, completed_at: day.beginning_of_day + 14.hours + 25.minutes
    )
    TimerSession.create!(
      user: user, kind: "short_break", duration_minutes: 5,
      started_at: day.beginning_of_day + 10.hours, completed_at: day.beginning_of_day + 10.hours + 5.minutes
    )

    assert_equal 50, TimerSession.focus_minutes_on(user, day)
  end
end
