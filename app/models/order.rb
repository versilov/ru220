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
  has_one :axiomus_order, :dependent => :destroy
  has_one :extra_post_order, :dependent => :destroy
  
  default_scope :order => 'created_at DESC'
  
  
  
  module PaymentType
    COD = 'Наложенный платёж' # Cash On Delivery
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
  
  
  
  def quantity
    if @quantity
      @quantity
    elsif self.total_quantity > 0
      @quantity = self.total_quantity
    else
      @quantity = 1
    end
  end
  
  def quantity= q
    @quantity = q.to_i
    if self.line_items.size > 0
      self.line_items[0].update_attribute(:quantity, q)
    end
  end
  
  def create_sd02_line_item(q)
    line_item = LineItem.new
    line_item.order_id = self.id
    line_item.product_id = SD02_PRODUCT_ID
    line_item.quantity = q
    
    if not line_item.save
      puts "Could not save line item. quantity == #{line_item.quantity}"
    end
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
  
  def mark_sent
    self.sent_at = Time.now
    self.add_event 'Отправлен'
    save
  end
  
  def sent?
    self.sent_at != nil
  end
  
  def postal?
    self.delivery_type == DeliveryType::POSTAL
  end
  
  def courier?
    self.delivery_type == DeliveryType::COURIER
  end
  
  def add_event(description)
    ev = OrderEvent.new
    ev.order_id = self.id
    ev.description = description
    ev.save
  end
  
  
  def status
    if self.courier?
      xml = %{<?xml version='1.0' standalone='yes'?>
      <singleorder>
        <mode>status</mode>
        <okey>#{self.axiomus_order.auth}</okey>
      </singleorder>}
      url = URI.parse('http://www.axiomus.ru/test/api_xml_test.php')
      post_params = { 'data' => xml }
      resp = Net::HTTP.post_form(url, post_params)
      puts resp
      
      doc = REXML::Document.new(resp.body)
      status = doc.elements['response/status']
      return status.text
    elsif self.postal?
      if self.extra_post_order
        self.extra_post_order.post_order.comment
      else
        #raise 'Postal order without extra_post_order object!'
      end
    else
      raise "Неизвестный способ доставки: #{self.delivery_type}"
    end
  end
  
  def post_num
    if self.extra_post_order
      self.extra_post_order.post_order.num
    else
      nil
    end
  end
  
end
