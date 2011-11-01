class AddReturnedAtToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :returned_at, :datetime
  end

  def self.down
    remove_column :orders, :returned_at
  end
end
