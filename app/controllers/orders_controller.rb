# encoding: utf-8

require 'net/http'
require 'rexml/document'


class OrdersController < ApplicationController
  skip_before_filter :authorize, :only => [:new, :create, :done, :parse_index]
  
  class Filter
    def initialize(pay, delivery, start_date, end_date)
      @pay_type = pay
      @delivery_type = delivery
      self.start_date = start_date
      self.end_date = end_date
    end
    
    attr_accessor :pay_type, :delivery_type, :start_date, :end_date
    
  end
  
  
  # GET /orders
  # GET /orders.xml
  # Contains huge filtering logic.
  def index
    @filter = Filter.new(Order::PaymentType::ALL, Order::DeliveryType::ALL, Date.yesterday, Date.today)
    
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

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.xml
  def new
    @order = Order.new

    if request.domain == 'localhost'   
      @order.client = 'Смирнов Сергей Игоревич'
      @order.index = '443096'
      @order.region = 'Самарская обл.'
      @order.city = 'Самара'
      @order.address = 'ул. Ленина, д. 2-Б, кв. 12'
      @order.phone = '+7 916 233 03 36'
      @order.email = 'client@mail.org'
      @order.pay_type = Order::PaymentType::COD
      @order.delivery_type = Order::DeliveryType::COURIER
    end

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
    @order = Order.new(params[:order])

    respond_to do |format|
      if @order.save
        @order.add_event 'Создан'
        @order.create_sd02_line_item(@order.quantity)
        
        if @order.delivery_type == Order::DeliveryType::COURIER
          # Send data to Axiomus
          status = send_order_to_axiomus(@order)
          if status.attributes['code'].to_i > 0
            format.html { 
              flash[:notice] = 'Не удалось передать заказ в службу курьерской доставки: ' + status.text;
              render :action => 'new'  }
          else
            @order.add_event 'Передан в Аксиомус'
          end
        end
        
        format.html { redirect_to(done_url, :notice => 'Order was successfully created.'); flash[:order_id] = @order.id }
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
        format.html { redirect_to(@order, :notice => 'Order was successfully updated.') }
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
  
  def send_order_to_axiomus(order)
    uid = 92
    date = Date.tomorrow
    start_time = '10:00'
    end_time = '18:00'
    cache = 'yes'
    cheque = 'yes'
    selsize = 'no'
    checksum_source = "#{uid}1#{order.total_quantity}#{order.total_price.to_i}#{date} #{start_time}#{cache}/#{cheque}/#{selsize}"
    puts "Checksum source: #{checksum_source}"
    checksum = Digest::MD5.hexdigest(checksum_source)
    xml = %{<?xml version='1.0' standalone='yes'?>
<singleorder>
<mode>new</mode>
<auth ukey="XXcd208495d565ef66e7dff9f98764XX" checksum="#{checksum}" />
<order inner_id="#{order.id}" name="#{order.client}"  address="#{order.index}, #{order.region}, #{order.city}, #{order.address}" from_mkad="0" d_date="#{date}" b_time="#{start_time}" e_time="#{end_time}">
   <contacts>тел. #{order.phone}</contacts>
   <description></description>
   <hidden_desc></hidden_desc>
   <services cash="#{cache}" cheque="#{cheque}" selsize="#{selsize}" />
   <items>
		<item name="Энергосберегатель"  weight="0.200" quantity="#{order.total_quantity}" price="#{order.line_items[0].product.price}" />
   </items>
</order>
</singleorder>}
    puts xml
    url = URI.parse('http://www.axiomus.ru/test/api_xml_test.php')
    post_params = { 'data' => xml }
    resp = Net::HTTP.post_form(url, post_params)
    
    puts resp.body
    
    doc = REXML::Document.new(resp.body)
    status = doc.elements['response/status']
    axiomus_status_code = status.attributes['code'].to_i
    
    status
  end
  
end
