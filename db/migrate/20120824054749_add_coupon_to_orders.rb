class AddCouponToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :coupon, :string, :limit => 32
  end

  def self.down
    remove_column :orders, :coupon
  end
end
