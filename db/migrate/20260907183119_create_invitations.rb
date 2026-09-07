class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.references :circle, null: false, foreign_key: true
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.references :invitee, null: true, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at
      t.datetime :accepted_at
      t.timestamps
    end
    add_index :invitations, :token, unique: true
    add_index :invitations, %i[circle_id invitee_id status]
  end
end
