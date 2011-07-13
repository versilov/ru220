class AddAliasToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :alias, :string
  end

  def self.down
    remove_column :articles, :alias
  end
end
