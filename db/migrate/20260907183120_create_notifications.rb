class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.integer :kind, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, %i[recipient_id read_at]
  end
end
