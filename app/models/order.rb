# encoding: UTF-8

class Order < ActiveRecord::Base
  class IndexValidator < ActiveModel::Validator
    def validate(record)
      index = record.index
      
      post_index = PostIndex.find_by_index(index.to_s)
      
      if post_index == nil
        record.errors[:index] << "не найден"
        return
      end
      
      # Check for delivery limits
      DeliveryLimit.find_all_by_index(index.to_s).each do |limit|
        # Convert to year 2000
        today = Date.civil(2000, Date.today.mon, Date.today.mday)
        
        if today.between?(limit.prbegdate, limit.prenddate)
          record.errors[:index] << "закрыт до #{limit.prenddate.strftime('%d-%m')}"
        end
      end
    end
  end
  
  has_many :line_items, :dependent => :destroy
  has_many :order_events, :dependent => :destroy
  
  default_scope :order => 'created_at DESC'
  
  
  
  module PaymentType
    COD = 'Наложенный платёж'
    ROBO = 'Робокасса'
    ALL = 'Все'
  end
  
  module DeliveryType
    POSTAL = 'Почта России'
    COURIER = 'Курьером по Москве и Питеру'
    ALL = 'Все'
  end
  
  PAYMENT_TYPES = [ PaymentType::COD, PaymentType::ROBO ]
  DELIVERY_TYPES = [ DeliveryType::POSTAL, DeliveryType::COURIER ]
  SD02_PRODUCT_ID = 1


  validates :index, :client, :address, :phone, :pay_type, :delivery_type, :presence => true
  validates :index, :length => 6..6,  :numericality => true
  validates :pay_type, :inclusion => PAYMENT_TYPES
  validates :delivery_type, :inclusion => DELIVERY_TYPES
  validates_with IndexValidator
  
  
  # Filters
  
  scope :cod,     :conditions => { :pay_type => PAYMENT_TYPES[0] }
  scope :robokassa, :conditions => { :pay_type => PAYMENT_TYPES[1] }
  
  FILTERS = [
    { :scope => 'all',        :label => 'Все' },
    { :scope => 'cod',        :label => 'Наложенный платёж' },
    { :scope => 'robokassa',  :label => 'Робокасса (предоплата)' },
  ]

  
  
  
  
  
  
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
  
  # Short name includes not only id, but also a city or region name for redundancy
  def short_name
    if city.length > 0
      "#{city}—#{id}"
    else
      "#{region}—#{id}"
    end
  end
  
 
  # Marks order as payed with the current timestamp and saves order.
  def mark_payed
    self.payed_at = Time.now
    self.add_event 'Оплачен'
    save
  end
  
  # True, if order was payed for (i.e. payed_at timestamp is not nil)
  def payed?
    self.payed_at != nil
  end
  
  def add_event(description)
    ev = OrderEvent.new
    ev.order_id = self.id
    ev.description = description
    ev.save
  end
  
end
