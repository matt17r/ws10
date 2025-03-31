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

ActiveRecord::Schema[8.0].define(version: 2025_03_30_053217) do
  create_table "assignments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.integer "number", null: false
    t.date "date", null: false
    t.string "location", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "results_ready"
    t.string "description"
    t.index ["location"], name: "index_events_on_location"
    t.index ["number"], name: "index_events_on_number", unique: true
  end

  create_table "results", force: :cascade do |t|
    t.integer "user_id"
    t.integer "event_id", null: false
    t.integer "time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_results_on_event_id"
    t.index ["user_id"], name: "index_results_on_user_id"
    t.check_constraint "user_id IS NOT NULL OR time IS NOT NULL", name: "check_user_or_time_not_null"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "results_count", default: 0, null: false
    t.integer "volunteers_count", default: 0, null: false
    t.string "name", null: false
    t.string "display_name", default: "Anonymous", null: false
    t.string "emoji", default: "👤", null: false
    t.index ["display_name"], name: "index_users_on_display_name"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["emoji"], name: "index_users_on_emoji"
    t.index ["name"], name: "index_users_on_name"
  end

  create_table "volunteers", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "event_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_volunteers_on_event_id"
    t.index ["user_id"], name: "index_volunteers_on_user_id"
  end

  add_foreign_key "assignments", "roles"
  add_foreign_key "assignments", "users"
  add_foreign_key "results", "events"
  add_foreign_key "results", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "volunteers", "events"
  add_foreign_key "volunteers", "users"
end
