class EnforceLocationRequirement < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :location_name, :string
    change_column_null :events, :location_id, false
  end
end
