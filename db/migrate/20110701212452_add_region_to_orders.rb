class AddRegionToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :region, :string
    add_column :orders, :area, :string
    add_column :orders, :city, :string
  end

  def self.down
    remove_column :orders, :city
    remove_column :orders, :area
    remove_column :orders, :region
  end
end
