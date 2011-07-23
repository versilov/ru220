# encoding: utf-8

require 'net/http'
require 'rexml/document'

class OrdersController < ApplicationController
  skip_before_filter :authorize, :only => [:new, :create, :done, :parse_index]
  
  # GET /orders
  # GET /orders.xml
  def index
    @filters = Order::FILTERS
    if params[:show] && @filters.collect { |f| f[:scope] }.include?(params[:show])
      @orders = Order.send(params[:show])
    elsif params[:store_id] && Store.find(params[:store_id])
      @orders = Order.find_all_by_store_id(params[:store_id])
    else
      @orders = Order.all
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
        @order.create_sd02_line_item(@order.quantity)
        
        if @order.delivery_type == Order::DeliveryType::COURIER
          # Send data to Axiomus
          status = send_order_to_axiomus(@order)
          if status.attributes['code'].to_i > 0
            format.html { 
              flash[:notice] = 'Не удалось передать заказ в службу курьерской доставки: ' + status.text;
              render :action => 'new'  }
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
