class AddOwnerToCircles < ActiveRecord::Migration[7.0]
  def change
    # The user who created the circle. Nullable so existing rows migrate cleanly;
    # new circles always set it (see CirclesController#create).
    add_reference :circles, :owner, null: true, foreign_key: { to_table: :users }
  end
end
