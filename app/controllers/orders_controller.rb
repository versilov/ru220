# encoding: utf-8

require 'net/http'
require 'rexml/document'
require 'nokogiri'
require 'erb'
require 'csv'


class OrdersController < ApplicationController
  skip_before_filter :authorize, :only => [:new, :create, :done, :parse_index, :search_index]
  
  class Filter
    def initialize(pay, delivery, start_date, end_date)
      @pay_type = pay
      @delivery_type = delivery
      self.start_date = start_date
      self.end_date = end_date
    end
    
    attr_accessor :pay_type, :delivery_type, :start_date, :end_date
    
  end
  
  class DeliveryTime
    DELIVERY_HOURS_FROM = (10..19).collect { |h| ["#{h}:00", h] }
    DELIVERY_HOURS_TO = (15..22).collect { |h| ["#{h}:00", h] }
    
    
    attr_accessor :city, :date, :from, :to
    
    
    def initialize(date, from, to, city)
      @date = date
      @from = from
      @to = to
      
      @city = city
    end
    

  end
  
  
  # GET /orders
  # GET /orders.xml
  # Contains huge filtering logic.
  def index
    @total_orders_num = Order.count
    
    @filter = Filter.new(Order::PaymentType::ALL, Order::DeliveryType::ALL, Date.yesterday, Date.tomorrow)
    
    if params[:filter] and params[:do_filter]
      # Filter button was pressed
      @start_date = Date.civil(params[:filter][:"start_date(1i)"].to_i,params[:filter][:"start_date(2i)"].to_i,params[:filter][:"start_date(3i)"].to_i)
      
      @end_date = Date.civil(params[:filter][:"end_date(1i)"].to_i,params[:filter][:"end_date(2i)"].to_i,params[:filter][:"end_date(3i)"].to_i)
      
      
      @pay_type = params[:filter][:pay_type]
      @delivery_type = params[:filter][:delivery_type]
      
      @filter = Filter.new(@pay_type, @delivery_type, @start_date, @end_date)
      
      query = "created_at >= :start and created_at <= :end"
      if @pay_type != Order::PaymentType::ALL
        query += " and pay_type = :pay_type"
      end
      if @delivery_type != Order::DeliveryType::ALL
        query += " and delivery_type = :delivery_type"
      end

      
      @orders = Order.where(query, {:start => @start_date, :end => @end_date, :pay_type => @pay_type, :delivery_type => @delivery_type })
      
      @orders_size = @orders.size # for total quantity display at header
      @orders = @orders.to_a().paginate(:page => params[:page], :per_page => 10)

    elsif params[:search] and params[:do_search]
      # Search button was pressed
      
      @search = params[:search]

      if @search.to_i > 0
        # Look for an order by number
        @orders = Order.find_all_by_id(@search.to_i)
      else
        # Look for an order by client name, city or address
        query = '%' + @search.downcase + '%'
        @orders = Order.where("lower(client) like ? or lower(city) like ? or lower(address) like ?", query, query, query)
      end
      
      @orders_size = @orders.size # for total quantity display at header
      @orders = @orders.to_a().paginate(:page => params[:page], :per_page => 10)
    else
      # Some other button (on of the two Resets) or no button were pressed.
      # Just give everything we've got.
      if params[:hideclosed]
        @orders = Order.where("sent_at isnull or payed_at isnull")
        @orders_size = @orders.size
        @orders = @orders.to_a().paginate :page => params[:page], :per_page => 10
      else
        @orders = Order.paginate :page => params[:page], :per_page => 10
        @orders_size = @total_orders_num
      end
    end
    


    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @orders }
    end
  end




  # GET /orders/1
  # GET /orders/1.xml
  def show
    @order = Order.find(params[:id])
    Time.zone = 'Moscow'
    
    @post_history_table_html = @order.get_post_history if @order.postal?
    @phone_history = OrdersController::get_phone_history(@order)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.xml
  def new
    @order = Order.new
    @delivery_time = DeliveryTime.new(Date.tomorrow.jd, 10, 15, 'Москва')
    
    if request.domain == 'localhost'   
      @order.client = 'Смирнов Сергей Игоревич'
      @order.index = '443096'
      @order.region = 'Самарская обл.'
      @order.city = 'Самара'
      @order.address = 'ул. Ленина, д. 2-Б, кв. 12'
      @order.phone = '+7 916 233 03 36'
      @order.email = 'stas.versilov@gmail.com'
    end
    
    @order.pay_type = Order::PaymentType::COD
    @order.delivery_type = Order::DeliveryType::POSTAL
    
    @is_cart = true

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
  end
  
  def create_order2(params, quantity=0)


    if params[:order][:delivery_type] == Order::DeliveryType::POSTAL
      order = ExtraPostOrder.new(params[:order])
    elsif params[:order][:delivery_type] == Order::DeliveryType::COURIER
      order = AxiomusOrder.new(params[:order])
      order.city = @delivery_time.city
      order.index = nil
      order.region = nil
      order.area = nil
      
      order.date = Date.jd(@delivery_time.date.to_i)
      order.from = @delivery_time.from
      order.to = @delivery_time.to
    else
      raise "Unknown delivery type: #{order.delivery_type}"
    end
    
    if quantity == 0
      quantity = order.quantity
    end
    
    if params[:discount] and current_user
      order.discount = 0.95 # 5% discount
    else
      order.discount = 1.0
    end

    if order.source == 'BigBuzzy'
      order.discount = 0.5
    end
    
    # String new line characters from user input
    order.address = order.address.gsub(/[\n\r]/, ' ') if order.address

    
    if not order.save
      @order = order
      raise RuntimeError, 'Could not save new order' + @order.errors.to_s
    end

    event = 'Создан'
    if current_user
      event += " пользователем #{current_user.login}"
    end
    order.add_event event
    order.create_sd02_line_item(quantity)
    order.reload
    
    if order.postpaid?
      @order = order
      if not order.send_to_delivery
        flash[:notice] = 'Не удалось прямо сейчас передать заказ в службу доставки. Попробуем ещё раз через час.'
      end
    end
    
    return order
  end
  
  def create_order(params)
    quantity = params[:order][:quantity].to_i
    
    if params[:order][:delivery_type] == Order::DeliveryType::POSTAL and params[:order][:pay_type] == Order::PaymentType::COD and quantity > 2
      # Russian Post has a 5 000 RUB limit for value of banderols, 
      # so we need to split orders, which contain more, than 2 products
      for i in 1..(quantity/2)
        if i == 1
          @order = create_order2(params, 2)
        else
          create_order2(params, 2)
        end
      end
      
      if quantity % 2 > 0
        create_order2(params, quantity % 2)
      end
    else
      # create order with any quantity client wished
      @order = create_order2(params)
    end
  end
  

  # POST /orders
  # POST /orders.xml
  def create
    # Store filter params
    dparams = params[:delivery_time]
    @delivery_time = DeliveryTime.new(dparams[:date], dparams[:from], dparams[:to], dparams[:city])
  

    respond_to do |format|
      begin
        create_order(params)
        format.html { redirect_to(done_url, :notice => 'Заказ успешно зарегистрирован.'); flash[:order_id] = @order.id }
      rescue => bang
        logger.error "Exception in order_controller.create: #{bang}"
        logger.error bang.backtrace.join("\n")
        format.html { render :action => "new" }
      end
    end
  end
  
  def done
    @order = Order.find(flash[:order_id])
    @is_done = true
    if @order.pay_type == Order::PaymentType::ROBO
      crc = Digest::MD5.hexdigest "energo220ru:#{@order.total_price}:#{@order.id}:electricity88"
      @robo_signature = crc
    end
    
    # Send order received email
    if @order.email
        begin
          Postman.new_order_email(@order).deliver
        rescue
          print "\n====Email sending error====\n"
        end
    end
  end
  
  
  # PUT /orders/1
  # PUT /orders/1.xml
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        @order.add_event "Изменён пользователем #{User.find_by_id(session[:user_id]).login}"
        format.html { redirect_to(order_url(@order), :notice => 'Order was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # PUT /orders/1/cancel
  def cancel
    @order = Order.find(params[:order_id])
    
    respond_to do |format|
      if @order.sent?
        format.html { redirect_to(orders_url, :notice => "Невозможно отменить отправленный заказ.") }
    elsif @order.cancel
        
        @order.add_event "Отменён пользователем #{User.find_by_id(session[:user_id]).login}"
        format.html { redirect_to(orders_url, :notice => "Заказ №#{@order.id} отменён.") }
        format.xml { head :ok }
      else
        format.html { redirect_to(orders.url, :notice => "Не удалось отменить заказ №#{@order.id}.") }
        format.xml { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.xml
  def destroy
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to(orders_url) }
      format.xml  { head :ok }
    end
  end
  
  
  def all_orders_csv
     # Return CSV file with all orders
    
    csv_string = CSV.generate :col_sep => ';' do |csv|
      csv << ['DATE', 'INDEX', 'REGION', 'AREA', 'CITY', 'ADRESAT', 'PHONE']
      
      Order.all.each do |order|
        unless order.canceled?
          csv << [order.created_at, order.index, order.region, order.area, order.city, order.client, order.phone]
        end
      end
    end
    
    csv_file_name = 'all_orders.csv' 
    
    ic = Iconv.new('WINDOWS-1251', 'UTF-8')
    csv_string = ic.iconv(csv_string)
    
    send_data csv_string,
            :type => 'text/csv; charset=windows-1251; header=present',
            :disposition => "attachment; filename=#{csv_file_name}"
  end
  
  
  # returns region, area and city by postal index
  def parse_index
    index = PostIndex.find_by_index(params[:index])
    
    if (index)
      respond_to do |format|
        format.html { render :text => index.region + ';' + index.area + ';' + index.city }
      end
    else
      respond_to do |format|
        format.html { render :text => '', :status => 404 }
      end
    end
  end
  
  def total_orders_num
    respond_to do |format|
      format.html { render :text => Order.count.to_s }
    end
  end
  
  
  # Returns indexes, that start with the given sequence
  def search_index
    part_of_index = params[:term]
    indexes = []
    
    if part_of_index
      indexes = PostIndex.where('"index" like ?', part_of_index + '%').select('"index", region, city').collect { |pi| {:value => pi.index, :label => pi.index + '-' + pi.city! } }
    end

    respond_to do |format|
      format.html { render :text => indexes.to_json }
    end
  end
  
  # Get phone calls history from the number, mentioned in order
  def OrdersController::get_phone_history(order)
    
    phone = order.phone.gsub(/\D/, '').gsub(/^(\d*)(\d{10})$/, '\2')
    
    if phone.length < 5
      return nil
    end
    
    req = Net::HTTP::Get.new(
      "/220ruXML/Default.aspx?login=220ru&passw=ERG220pass2007&msisdn=#{phone}")
    resp = Net::HTTP.start('stat.smsboom.ru') {|http|
      http.request(req)
    }
    
    doc = REXML::Document.new(resp.body)
    
    if doc.elements.to_a('root/Call').size > 0
      return doc
    else
      return nil
    end
  rescue SocketError
    puts "Could not reach http://stat.smsboom.ru"
    return nil
  end
  
end
