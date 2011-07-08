# encoding: UTF-8
class Order < ActiveRecord::Base
  has_many :line_items, :dependent => :destroy
  
  default_scope :order => 'created_at DESC'
  
  validates :index, :client, :city, :address, :phone, :pay_type, :presence => true
  
  module PaymentType
    COD = 'Наложенный платёж'
    ROBO = 'Робокасса'
  end
  
  PAYMENT_TYPES = [ PaymentType::COD, PaymentType::ROBO ]
  SD02_PRODUCT_ID = 1

  
  validates :index, :length => 6..6,  :numericality => true
  
  attr_accessor :quantity
  
  def create_sd02_line_item(quantity)
    line_item = LineItem.new
    line_item.order_id = self.id
    line_item.product_id = SD02_PRODUCT_ID
    line_item.quantity = quantity
    
    line_item.save
  end
  
  def total_price
   line_items.to_a.sum { |item| item.total_price }
  end
  
  def total_quantity
    line_items.to_a.sum { |item| item.quantity }
  end
  
end
