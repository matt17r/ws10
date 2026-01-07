class AddFinishLinkingEnabledToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :finish_linking_enabled, :boolean, default: false, null: false
    add_index :events, :finish_linking_enabled, unique: true, where: "finish_linking_enabled = 1", name: "index_events_on_single_active"
  end
end
