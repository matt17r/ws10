class CreateLocationsAndUpdateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :nickname, null: false
      t.string :subtitle, null: false
      t.text :full_address, null: false
      t.text :start_point_description, null: false
      t.string :google_maps_url, null: false
      t.string :apple_maps_url, null: false
      t.text :facilities, null: false
      t.text :course_description, null: false
      t.string :strava_route_url, null: false
      t.string :strava_embed_id, null: false
      t.string :strava_map_hash, null: false
      t.string :start_image_1
      t.string :start_image_2
      t.string :og_title
      t.text :og_description

      t.timestamps

      t.index :slug, unique: true
      t.index :name, unique: true
    end

    rename_column :events, :location, :location_name
    add_reference :events, :location, foreign_key: true
    add_column :events, :facebook_url, :string
    add_column :events, :strava_url, :string
    change_column_default :events, :results_ready, from: nil, to: false
    change_column_null :events, :results_ready, false
  end
end
