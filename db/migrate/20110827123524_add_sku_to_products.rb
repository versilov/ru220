class AddSkuToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :sku, :string, :limit => 32
  end

  def self.down
    remove_column :products, :sku
  end
end
