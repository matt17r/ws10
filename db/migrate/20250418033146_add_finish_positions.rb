class AddFinishPositions < ActiveRecord::Migration[8.0]
  def change
    create_table :finish_positions do |t|
      t.references :user, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :position
      t.timestamps
      t.index [ :user_id, :event_id ], unique: true
      t.index [ :position, :event_id ], unique: true
    end
  end
end
