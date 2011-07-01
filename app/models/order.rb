# encoding: UTF-8
class Order < ActiveRecord::Base
  validates :index, :client, :address, :phone, :email, :presence => true
  
  validates :index, :length => 6..6,  :numericality => true
  
end
