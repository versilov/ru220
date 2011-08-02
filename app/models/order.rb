# encoding: UTF-8

class Order < ActiveRecord::Base
  class IndexValidator < ActiveModel::Validator
    def validate(record)
      
      if record.delivery_type == DeliveryType::COURIER
        # Don't need index for courier delivery
        return
      end
      
      index = record.index
      
      if not index
        record.errors[:index] << "является обязательным полем"
        return
      end
      
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
    COD = 'Наложенный платёж' # Cash On Delivery
    ROBO = 'Робокасса'
    ALL = 'Все'
  end
  
  module DeliveryType
    POSTAL = 'Почта России'
    COURIER = 'Курьером по Москве и Санкт-Петербургу'
    ALL = 'Все'
  end
  
  PAYMENT_TYPES = [ PaymentType::COD, PaymentType::ROBO ]
  DELIVERY_TYPES = [ DeliveryType::POSTAL, DeliveryType::COURIER ]
  SD02_PRODUCT_ID = 1


  validates :client, :address, :phone, :pay_type, :delivery_type, :presence => true
  validates :index, :length => { :is => 6, :allow_blank => true },  :numericality => { :on => :save, :only_integer => true, :allow_nil => true }
  validates :pay_type, :inclusion => PAYMENT_TYPES
  validates :delivery_type, :inclusion => DELIVERY_TYPES
  validates_with IndexValidator
  
    # Returns city name, event if it's stored in the region field (as for capitals)
  def city!
    if self.city.length > 0
      return self.city
    else
      return self.region
    end
  end

  
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
    self.update_attribute(:payed_at, Time.now)
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
  
  def prepaid?
    self.pay_type == PaymentType::ROBO
  end
  
  def postpaid?
    self.pay_type == PaymentType::COD
  end
  
  def send_to_delivery
    raise "Not implemented. Implement in child classes"
  end
  
  def add_event(description)
    ev = OrderEvent.new
    ev.order_id = self.id
    ev.description = description
    ev.save
  end
  
  
  def status
    if self.courier?
      if not self.axiomus_order
        return 'Не найден объект-связка с Аксиомусом'
      end
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
        begin
          self.extra_post_order.post_order.comment
        rescue Exception
          STDERR.puts "Order #{self} without a corresponding post_order object in extrapost system."
          return "Не найден сопутствующий объект в системе ЭкстраПост"
        end
      else
        return 'Почтовый заказ без объекта-связки с ЭкстраПостом!'
      end
    else
      raise "Неизвестный способ доставки: #{self.delivery_type}"
    end
  end
  

  
  
end




