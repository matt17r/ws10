class CreateCheckIns < ActiveRecord::Migration[8.1]
  def change
    create_table :check_ins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.datetime :checked_in_at, null: false
      t.timestamps

      t.index [ :user_id, :event_id ], unique: true, name: "index_check_ins_on_user_and_event"
    end
  end
end
