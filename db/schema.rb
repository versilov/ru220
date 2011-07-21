# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110721074946) do

  create_table "articles", :force => true do |t|
    t.string   "title"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "alias"
  end

  create_table "delivery_limits", :id => false, :force => true do |t|
    t.string "index",      :limit => 6
    t.string "opsname",    :limit => 100
    t.date   "actdate"
    t.date   "prbegdate"
    t.date   "prenddate"
    t.string "delivtype",  :limit => 30
    t.string "delivpnt",   :limit => 100
    t.string "baserate"
    t.string "basecoeff"
    t.string "transfcnt"
    t.string "ratezone"
    t.date   "cfactdate"
    t.string "delivindex", :limit => 6
  end

  create_table "line_items", :force => true do |t|
    t.integer  "product_id"
    t.integer  "order_id"
    t.integer  "quantity"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "orders", :force => true do |t|
    t.integer  "index"
    t.string   "client"
    t.text     "address"
    t.string   "phone"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "region"
    t.string   "area"
    t.string   "city"
    t.string   "pay_type"
    t.string   "delivery_type"
    t.datetime "payed_at"
    t.datetime "sent_at"
  end

  create_table "post_indices", :id => false, :force => true do |t|
    t.string "index",    :limit => 6
    t.string "opsname",  :limit => 60
    t.string "opstype",  :limit => 50
    t.string "opssubm",  :limit => 6
    t.string "region",   :limit => 60
    t.string "autonom",  :limit => 60
    t.string "area",     :limit => 60
    t.string "city",     :limit => 60
    t.string "city_1",   :limit => 60
    t.date   "actdate"
    t.string "indexold", :limit => 6
  end

  create_table "products", :force => true do |t|
    t.string   "title"
    t.string   "image_url"
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
