# encoding: utf-8

require 'net/http'
require 'rexml/document'
require 'nokogiri'
require 'erb'


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
    else
      # Some other button (on of the two Resets) or no button were pressed.
      # Just give everything we've got.
      @orders = Order.all
    end

    @orders = @orders.to_a().paginate(:page => params[:page], :per_page => 10)

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
    
    raise "Exception!!!"
    
    @post_history_table_html = @order.get_post_history if @order.postal?

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
      @order.email = 'client@mail.org'
    end
    
    @order.pay_type = Order::PaymentType::COD
    @order.delivery_type = Order::DeliveryType::POSTAL

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
  end

  # POST /orders
  # POST /orders.xml
  def create
    dparams = params[:delivery_time]
    @delivery_time = DeliveryTime.new(dparams[:date], dparams[:from], dparams[:to], dparams[:city])
  


    if params[:order][:delivery_type] == Order::DeliveryType::POSTAL
      @order = ExtraPostOrder.new(params[:order])
    elsif params[:order][:delivery_type] == Order::DeliveryType::COURIER
      @order = AxiomusOrder.new(params[:order])
      @order.city = @delivery_time.city
      @order.index = nil
      @order.region = nil
      @order.area = nil
      
      @order.date = Date.jd(@delivery_time.date.to_i)
      @order.from = @delivery_time.from
      @order.to = @delivery_time.to
      
    else
      raise"Unknown delivery type: #{@order.delivery_type}"
    end
    

    respond_to do |format|
      if @order.save
        @order.add_event 'Создан'
        @order.create_sd02_line_item(@order.quantity)
        @order.reload

        if @order.postpaid?
          if not @order.send_to_delivery
            format.html { 
              flash[:notice] = 'Не удалось передать заказ в службу доставки';
              render :action => 'new'  }
          end
        end
        
        format.html { redirect_to(done_url, :notice => 'Заказ успешно зарегистрирован.'); flash[:order_id] = @order.id }
        format.xml  { render :xml => @order, :status => :created, :location => @order }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @order.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def done
    @order = Order.find(flash[:order_id])
    if @order.pay_type == Order::PaymentType::ROBO
      crc = Digest::MD5.hexdigest "energo220ru:#{@order.total_price}:#{@order.id}:electricity88"
      
      @robo_signature = crc
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
  
  
  # Returns indexes, that start with the given sequence
  def search_index
    part_of_index = params[:term]
    indexes = PostIndex.where('"index" like ?', part_of_index + '%').select('"index", region, city').collect { |pi| {:value => pi.index, :label => pi.index + '-' + pi.city! } }
    puts indexes
    respond_to do |format|
      format.html { render :text => indexes.to_json }
    end
  end
  
end
