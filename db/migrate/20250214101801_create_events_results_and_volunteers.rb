class CreateEventsResultsAndVolunteers < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.integer :number, null: false
      t.date :date, null: false
      t.string :location, null: false

      t.timestamps
    end
    add_index :events, :number, unique: true
    add_index :events, :location

    create_table :results do |t|
      t.references :user, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :time, null: true

      t.timestamps
    end
    add_check_constraint :results, "user_id IS NOT NULL OR time IS NOT NULL", name: "check_user_or_time_not_null"
  end

  create_table :volunteers do |t|
    t.references :user, null: false, foreign_key: true
    t.references :event, null: false, foreign_key: true
    t.string :role, null: false

    t.timestamps
  end

  change_table :users do |t|
    t.integer :results_count, null: false, default: 0
    t.integer :volunteers_count, null: false, default: 0
  end
end
