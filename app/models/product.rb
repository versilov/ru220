class Product < ActiveRecord::Base
  validates :title, :image_url, :price, :presence => true
  
  has_many :line_items
end
