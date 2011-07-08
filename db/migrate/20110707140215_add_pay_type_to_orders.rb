class AddPayTypeToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :pay_type, :string
  end

  def self.down
    remove_column :orders, :pay_type
  end
end
