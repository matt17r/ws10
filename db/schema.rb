# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_17_192022) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "badges", force: :cascade do |t|
    t.string "badge_family", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "level", null: false
    t.integer "level_order", null: false
    t.string "name", null: false
    t.boolean "repeatable", default: false, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["badge_family", "level_order"], name: "index_badges_on_badge_family_and_level_order", unique: true
    t.index ["slug"], name: "index_badges_on_slug", unique: true
  end

  create_table "check_ins", force: :cascade do |t|
    t.datetime "checked_in_at", null: false
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_check_ins_on_event_id"
    t.index ["user_id", "event_id"], name: "index_check_ins_on_user_and_event", unique: true
    t.index ["user_id"], name: "index_check_ins_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description"
    t.string "facebook_url"
    t.integer "location_id", null: false
    t.integer "number", null: false
    t.string "status", default: "draft", null: false
    t.string "strava_url"
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_events_on_location_id"
    t.index ["number"], name: "index_events_on_number", unique: true
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "finish_positions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "discarded", default: false, null: false
    t.integer "event_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["event_id"], name: "index_finish_positions_on_event_id"
    t.index ["position", "event_id"], name: "index_finish_positions_on_position_and_event_id", unique: true
    t.index ["user_id", "event_id"], name: "index_finish_positions_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_finish_positions_on_user_id"
  end

  create_table "finish_times", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "position"
    t.integer "time"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_finish_times_on_event_id"
    t.index ["position"], name: "index_finish_times_on_position"
  end

  create_table "locations", force: :cascade do |t|
    t.string "apple_maps_url", null: false
    t.text "course_description", null: false
    t.datetime "created_at", null: false
    t.text "facilities", null: false
    t.text "full_address", null: false
    t.string "google_maps_url", null: false
    t.string "name", null: false
    t.string "nickname", null: false
    t.text "og_description"
    t.string "og_title"
    t.string "slug", null: false
    t.string "start_image_1"
    t.string "start_image_2"
    t.text "start_point_description", null: false
    t.string "strava_embed_id", null: false
    t.string "strava_map_hash", null: false
    t.string "strava_route_url", null: false
    t.string "subtitle", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["slug"], name: "index_locations_on_slug", unique: true
  end

  create_table "results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.integer "time"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["event_id"], name: "index_results_on_event_id"
    t.index ["user_id", "event_id"], name: "index_results_on_user_id_and_event_id", unique: true, where: "user_id IS NOT NULL"
    t.index ["user_id"], name: "index_results_on_user_id"
    t.check_constraint "user_id IS NOT NULL OR time IS NOT NULL", name: "check_user_or_time_not_null"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_badges", force: :cascade do |t|
    t.integer "badge_id", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.integer "event_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["badge_id"], name: "index_user_badges_on_badge_id"
    t.index ["earned_at"], name: "index_user_badges_on_earned_at"
    t.index ["event_id"], name: "index_user_badges_on_event_id"
    t.index ["user_id", "badge_id"], name: "index_user_badges_on_user_id_and_badge_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "display_name", default: "Anonymous", null: false
    t.string "email_address", null: false
    t.string "emoji", default: "👤", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "results_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "volunteers_count", default: 0, null: false
    t.index ["display_name"], name: "index_users_on_display_name"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["emoji"], name: "index_users_on_emoji"
    t.index ["name"], name: "index_users_on_name"
  end

  create_table "volunteers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "event_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["event_id"], name: "index_volunteers_on_event_id"
    t.index ["user_id"], name: "index_volunteers_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "roles"
  add_foreign_key "assignments", "users"
  add_foreign_key "check_ins", "events"
  add_foreign_key "check_ins", "users"
  add_foreign_key "events", "locations"
  add_foreign_key "finish_positions", "events"
  add_foreign_key "finish_positions", "users"
  add_foreign_key "finish_times", "events"
  add_foreign_key "results", "events"
  add_foreign_key "results", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_badges", "badges"
  add_foreign_key "user_badges", "events"
  add_foreign_key "user_badges", "users"
  add_foreign_key "volunteers", "events"
  add_foreign_key "volunteers", "users"
end
