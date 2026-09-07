class AddUniqueIndexesToMembershipTables < ActiveRecord::Migration[7.0]
  def up
    dedupe :user_circles, %w[user_id circle_id]
    dedupe :user_events, %w[user_id event_id]
    dedupe :circle_events, %w[circle_id event_id]

    add_index :user_circles, %i[user_id circle_id], unique: true
    add_index :user_events, %i[user_id event_id], unique: true
    add_index :circle_events, %i[circle_id event_id], unique: true
  end

  def down
    remove_index :user_circles, %i[user_id circle_id]
    remove_index :user_events, %i[user_id event_id]
    remove_index :circle_events, %i[circle_id event_id]
  end

  private

  # Keep the oldest row for each pair so payments/splittees pointing at it survive.
  def dedupe(table, columns)
    cols = columns.join(", ")
    execute <<~SQL
      DELETE FROM #{table} a
      USING #{table} b
      WHERE a.id > b.id AND (#{columns.map { |c| "a.#{c} = b.#{c}" }.join(' AND ')})
    SQL
  end
end
