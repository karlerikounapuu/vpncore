# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_10_143805) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "servers", force: :cascade do |t|
    t.string "name"
    t.string "uuid"
    t.string "ip_addr"
    t.string "netmask"
    t.integer "ovpn_port"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "initiator"
  end

  create_table "vpn_clients", force: :cascade do |t|
    t.string "ident"
    t.string "uuid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "server_id"
    t.index ["server_id"], name: "index_vpn_clients_on_server_id"
  end

end
