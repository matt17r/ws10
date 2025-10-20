class AddUniqueIndexToResults < ActiveRecord::Migration[8.0]
  def change
    add_index :results, [:user_id, :event_id], unique: true, where: "user_id IS NOT NULL"
  end
end
