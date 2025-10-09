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

ActiveRecord::Schema[8.0].define(version: 2025_10_08_213418) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "events", force: :cascade do |t|
    t.bigint "session_id", null: false
    t.string "event_type", null: false
    t.string "url"
    t.string "referrer"
    t.string "user_agent"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_events_on_created_at"
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["session_id"], name: "index_events_on_session_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_token", null: false
    t.string "country"
    t.string "city"
    t.string "initial_referrer"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_token"], name: "index_sessions_on_session_token", unique: true
  end

  add_foreign_key "events", "sessions"
end
