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

ActiveRecord::Schema[8.0].define(version: 2025_07_30_034414) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alert_actions", force: :cascade do |t|
    t.bigint "alert_id", null: false
    t.string "action_type"
    t.string "status"
    t.jsonb "metadata"
    t.datetime "executed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["alert_id"], name: "index_alert_actions_on_alert_id"
  end

  create_table "alert_rules", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "rule_type"
    t.string "name"
    t.text "description"
    t.jsonb "conditions"
    t.boolean "enabled"
    t.decimal "action_rate"
    t.datetime "last_triggered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_alert_rules_on_store_id"
  end

  create_table "alerts", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "rule_type"
    t.string "status"
    t.string "severity"
    t.string "title"
    t.text "description"
    t.jsonb "metadata"
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.decimal "money_saved"
    t.integer "time_saved"
    t.decimal "action_rate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resolved_by_id"], name: "index_alerts_on_resolved_by_id"
    t.index ["store_id"], name: "index_alerts_on_store_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name"
    t.string "shopify_domain"
    t.string "stripe_account_id"
    t.string "slack_webhook_url"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.boolean "active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.bigint "store_id", null: false
    t.string "event_type"
    t.jsonb "payload"
    t.boolean "processed"
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_webhook_events_on_store_id"
  end

  add_foreign_key "alert_actions", "alerts"
  add_foreign_key "alert_rules", "stores"
  add_foreign_key "alerts", "stores"
  add_foreign_key "alerts", "users", column: "resolved_by_id"
  add_foreign_key "webhook_events", "stores"
end
