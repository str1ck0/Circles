class MakePrivateFlagsNonNullable < ActiveRecord::Migration[7.0]
  def up
    %i[circles events].each do |table|
      execute "UPDATE #{table} SET private = FALSE WHERE private IS NULL"
      change_column_default table, :private, from: nil, to: false
      change_column_null table, :private, false
    end
  end

  def down
    %i[circles events].each do |table|
      change_column_null table, :private, true
      change_column_default table, :private, from: false, to: nil
    end
  end
end
