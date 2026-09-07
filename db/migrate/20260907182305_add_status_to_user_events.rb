class AddStatusToUserEvents < ActiveRecord::Migration[7.0]
  def up
    add_column :user_events, :status, :integer, default: 0, null: false
    # Every existing row was a binary "attending", which maps to `going` (1), not the
    # new default of `invited` (0).
    execute "UPDATE user_events SET status = 1"
  end

  def down
    remove_column :user_events, :status
  end
end
