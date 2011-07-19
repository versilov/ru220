# encoding: utf-8

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
      @order.pay_type = Order::PaymentType::ROBO
      @order.delivery_type = Order::DeliveryType::POSTAL
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
      
      @robo_url = %{http://test.robokassa.ru/Index.aspx?MrchLogin=energo220ru&OutSum=#{@order.total_price}&InvId=#{@order.id}&IncCurrLabel=BANKOCEAN2R&Desc=EnergoSberegatel&SignatureValue=#{crc}&Culture=ru&Encoding=utf-8}
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
end
