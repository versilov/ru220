class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.integer :index
      t.string :client
      t.text :address
      t.string :phone
      t.string :email

      t.timestamps
    end
  end

  def self.down
    drop_table :orders
  end
end
