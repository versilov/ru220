# encoding: UTF-8

class Order < ActiveRecord::Base
  class IndexValidator < ActiveModel::Validator
    def validate(record)
      index = record.index
      
      post_index = PostIndex.find_by_index(index)
      
      if post_index == nil
        record.errors[:index] << "не найден"
        return
      end
      
      # Check for delivery limits
      DeliveryLimit.find_all_by_index(index).each do |limit|
        # Convert to year 2000
        today = Date.civil(2000, Date.today.mon, Date.today.mday)
        
        if today.between?(limit.prbegdate, limit.prenddate)
          record.errors[:index] << "закрыт до #{limit.prenddate.strftime('%d-%m')}"
        end
      end
    end
  end
  
  has_many :line_items, :dependent => :destroy
  
  default_scope :order => 'created_at DESC'
  
  
  
  module PaymentType
    COD = 'Наложенный платёж'
    ROBO = 'Робокасса'
  end
  
  PAYMENT_TYPES = [ PaymentType::COD, PaymentType::ROBO ]
  SD02_PRODUCT_ID = 1


  validates :index, :client, :city, :address, :phone, :pay_type, :presence => true
  validates :index, :length => 6..6,  :numericality => true
  validates :pay_type, :inclusion => PAYMENT_TYPES
  validates_with IndexValidator
  
  
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
