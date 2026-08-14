require "test_helper"

# The Pomodoro timer is the product and the public root. Guests get the full
# timer with no account; signing in adds persisted session history.
class HomePageTest < ActionDispatch::IntegrationTest
  test "root serves the Pomodoro timer to guests" do
    get root_path

    assert_response :success
    assert_select "h1", text: /timer/i
    assert_select "[data-controller=timer]"
    assert_select "[data-timer-signed-in-value=false]"
    assert_select ".timer-card__time"
    assert_select "button", text: "Start"
    assert_select "button", text: "Reset"
  end

  test "root serves the timer with history to signed-in users" do
    sign_in users(:confirmed)

    get root_path

    assert_response :success
    assert_select "[data-timer-signed-in-value=true]"
    assert_select "a[href=?]", history_path
  end

  test "history requires sign in" do
    get history_path

    assert_redirected_to root_path
  end

  test "signed-in history page lists sessions" do
    user = users(:confirmed)
    TimerSession.create!(
      user: user, kind: "focus", duration_minutes: 25,
      started_at: 25.minutes.ago, completed_at: Time.current
    )
    sign_in user

    get history_path

    assert_response :success
    assert_select ".timer-list__item", minimum: 1
    assert_select ".timer-list__kind", text: "focus"
  end
end
