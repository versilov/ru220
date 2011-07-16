class AddDeliveryTypeToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :delivery_type, :string
  end

  def self.down
    remove_column :orders, :delivery_type
  end
end
