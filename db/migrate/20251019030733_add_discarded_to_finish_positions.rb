class AddDiscardedToFinishPositions < ActiveRecord::Migration[8.0]
  def change
    add_column :finish_positions, :discarded, :boolean, default: false, null: false
  end
end
