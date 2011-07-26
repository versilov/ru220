class CreateExtraPostOrders < ActiveRecord::Migration
  def self.up
    create_table :extra_post_orders do |t|
      t.integer :order_id
      t.integer :post_order_id

      t.timestamps
    end
  end

  def self.down
    drop_table :extra_post_orders
  end
end
