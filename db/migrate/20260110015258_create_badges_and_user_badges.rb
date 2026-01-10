class CreateBadgesAndUserBadges < ActiveRecord::Migration[8.1]
  def change
    create_table :badges do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :badge_family, null: false
      t.string :level, null: false
      t.integer :level_order, null: false
      t.boolean :repeatable, default: false, null: false

      t.timestamps

      t.index :slug, unique: true
      t.index [ :badge_family, :level_order ], unique: true
    end

    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :badge, null: false, foreign_key: true
      t.datetime :earned_at, null: false

      t.timestamps

      t.index [ :user_id, :badge_id ]
      t.index :earned_at
    end
  end
end
