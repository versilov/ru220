# encoding: UTF-8
class Order < ActiveRecord::Base
  validates :index, :client, :city, :address, :phone, :presence => true

  
  validates :index, :length => 6..6,  :numericality => true
  
end
