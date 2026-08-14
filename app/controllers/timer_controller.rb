class TimerController < ApplicationController
  # The Pomodoro timer is the product and the public root: guests can run it
  # with no account. Signing in adds persisted history (see #history).
  def show
    @recent = if user_signed_in?
      TimerSession.for_user(current_user).chronological.limit(10)
    else
      []
    end
  end

  # Signed-in users can review completed sessions with per-day focus totals.
  def history
    return redirect_to(root_path, alert: "Sign in to view your session history.") unless user_signed_in?

    @sessions = TimerSession.for_user(current_user).chronological
    @focus_minutes_by_day = TimerSession.for_user(current_user).focus
      .group_by { |s| s.completed_at.to_date }
      .transform_values { |sessions| sessions.sum(&:duration_minutes) }
  end

  # Called by the timer JavaScript when a session completes while signed in.
  # Guests get a 204 — the timer works entirely in the browser for them.
  def record
    return head(:no_content) unless user_signed_in?

    kind = params[:kind]
    duration = params[:duration_minutes].to_i

    if TimerSession::KINDS.include?(kind) && duration.positive?
      now = Time.current
      session = TimerSession.create!(
        user: current_user,
        kind: kind,
        duration_minutes: duration,
        started_at: now - duration.minutes,
        completed_at: now
      )
      render json: session, status: :created
    else
      head :unprocessable_entity
    end
  end
end
