class AddCanceledAtToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :canceled_at, :timestamp
  end

  def self.down
    remove_column :orders, :canceled_at
  end
end
