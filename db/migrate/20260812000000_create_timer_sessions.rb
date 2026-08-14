class CreateTimerSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :timer_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false, default: "focus"
      t.integer :duration_minutes, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at, null: false

      t.timestamps
    end

    add_index :timer_sessions, [:user_id, :completed_at]
  end
end
