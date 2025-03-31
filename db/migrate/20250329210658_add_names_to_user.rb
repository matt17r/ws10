class AddNamesToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string, null: false
    add_index :users, :name
    add_column :users, :display_name, :string, null: false, default: "Anonymous"
    add_index :users, :display_name
    add_column :users, :emoji, :string, null: false, default: "👤"
    add_index :users, :emoji
  end
end
