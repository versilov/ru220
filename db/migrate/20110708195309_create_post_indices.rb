class CreatePostIndices < ActiveRecord::Migration
  def self.up
    create_table :post_indices, :id => false do |t|
      t.string :index, :limit => 6
      t.string :opsname, :limit => 60
      t.string :opstype, :limit => 50
      t.string :opssubm, :limit => 6
      t.string :region, :limit => 60
      t.string :autonom, :limit => 60
      t.string :area, :limit => 60
      t.string :city, :limit => 60
      t.string :city_1, :limit => 60
      t.date :actdate
      t.string :indexold, :limit => 6
    end
  end

  def self.down
    drop_table :post_indices
  end
end
