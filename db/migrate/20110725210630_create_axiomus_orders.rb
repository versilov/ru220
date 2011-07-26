class CreateAxiomusOrders < ActiveRecord::Migration
  def self.up
    create_table :axiomus_orders do |t|
      t.integer :order_id
      t.integer :axiomus_id
      t.string :auth

      t.timestamps
    end
  end

  def self.down
    drop_table :axiomus_orders
  end
end
