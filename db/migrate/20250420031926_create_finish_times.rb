class CreateFinishTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :finish_times do |t|
      t.references :event, null: false, foreign_key: true
      t.integer :position
      t.integer :time

      t.timestamps
    end
    add_index :finish_times, :position
  end
end
