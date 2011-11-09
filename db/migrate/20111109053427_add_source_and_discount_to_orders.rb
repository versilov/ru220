class AddSourceAndDiscountToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :source, :string
    add_column :orders, :discount, :decimal, :null => false, :default => 1.0
  end

  def self.down
    remove_column :orders, :discount
    remove_column :orders, :source
  end
end
