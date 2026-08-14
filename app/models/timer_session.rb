class TimerSession < ApplicationRecord
  KINDS = %w[focus short_break long_break].freeze

  belongs_to :user

  validates :kind, inclusion: { in: KINDS }
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :started_at, :completed_at, presence: true

  scope :for_user, ->(user) { where(user: user) }
  scope :focus, -> { where(kind: "focus") }
  scope :chronological, -> { order(completed_at: :desc) }

  def self.focus_minutes_on(user, day)
    for_user(user).focus
      .where(completed_at: day.all_day)
      .sum(:duration_minutes)
  end
end
