# encoding: utf-8

require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:one)
    @delivery_attrs = {:"date(1i)" => '2011', :"date(2i)" => '9', :"date(3i)" => '9', :from => '11', :to => '15', :city => 'Москва' }
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:orders)
    
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create order" do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 1
    assert_difference('Order.count', 1) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
    
    fresh_order = Order.find(flash[:order_id].to_i)
    assert_not_nil fresh_order
    assert_equal 1.0, fresh_order.discount    # no discount by default
  end
  
  test "should create order with newlines in address" do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 1
    order_attrs['address'] += "\nnew lline\nnewline\n"
    assert_difference('Order.count', 1) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
    
    fresh_order = Order.find(flash[:order_id].to_i)
    assert_not_nil fresh_order
    assert_equal nil, fresh_order.address =~ /[\n\r]/
  end

  
  test 'should create order with discount' do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 1
    assert_difference('Order.count', 1) do
      post :create, :order => order_attrs, :discount => 1, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
    
    fresh_order = Order.find(flash[:order_id].to_i)
    assert_not_nil fresh_order
    assert_equal 0.95, fresh_order.discount
  end
  
  test "should create order with errors" do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 3
    order_attrs[:index] = 123456
    assert_no_difference('Order.count') do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    
    assert_template 'orders/new'
    
  end

  test "should show order" do
    get :show, :id => @order.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @order.to_param
    assert_response :success
  end

  test "should update order" do
    put :update, :id => @order.to_param, :order => @order.attributes
    assert_redirected_to order_path(@order)
  end
  
  test 'should cancel order' do
    put :cancel, :order_id => @order.to_param
    assert_redirected_to orders_path
    @order.reload
    assert @order.canceled?
  end

  test "should destroy order" do
    assert_difference('Order.count', -1) do
      delete :destroy, :id => @order.to_param
    end

    assert_redirected_to orders_path
  end
  
  test 'should apply search criteria' do
    get :index, :search => 'Poupk', :do_search => 'Искать'
    assert_response :success
    assert_template 'orders/index'

    assert_not_nil assigns(:orders)
    assert assigns(:orders).size == 1, 'just one order found'
    order = assigns(:orders)[0]
    
    assert order.client.include? 'Poupk'
  end
  
  
  test 'should find order by number' do
    get :index, :search => orders(:two).id, :do_search => 'Искать'
    assert_response :success
    assert_template 'orders/index'
    
    assert_not_nil assigns(:orders)
    assert_equal 1, assigns(:orders).size, 'should be just one order'
    assert_equal orders(:two).id, assigns(:orders)[0].id
  end
  
  
  
  test 'should filter orders' do
    return # .where() does not work correctly, possible reason -- encoding or locale
    get :index, :filter => { :pay_type => Order::PaymentType::ALL,
      :delivery_type => Order::DeliveryType::ALL, 
      :'start_date(1i)' => Date.yesterday.year, :'start_date(2i)' => Date.yesterday.month, :'start_date(3i)' => Date.yesterday.day-3,
      :'end_date(1i)' => Date.today.year, :'end_date(2i)' => Date.today.month, :'end_date(3i)' => Date.today.day }, 
      :do_filter => 'Фильтровать'
    assert_response :success
    assert_template 'orders/index'
    
    assert_not_nil assigns(:orders)
    assert_equal 2, assigns(:orders).size, 'should be two courier orders in orders.yml'
  end
  
  test 'should get region, area, city by index' do
    xhr :get, :parse_index, :index => '123456'
    assert_response :missing
    
    xhr :get, :parse_index, :index => '443099'
    assert_response :success
    parts = @response.body.split(';')
    region = parts[0]
    area = parts[1]
    city = parts[2]
    
    post_index = PostIndex.find_by_index('443099')
    assert_equal region, post_index.region
    assert_equal area, post_index.area
    assert_equal city, post_index.city
  end
  
  test 'should search index' do
    xhr :get, :search_index
    assert_response :success
    indexes = JSON.parse @response.body
    assert indexes.respond_to? :to_ary
    assert indexes.size == 0
  end
  
  # COD orders with quantity greater, than 2,
  # should be split in not-more-than-two-items orders
  test 'should split big order in two' do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 3
    order_attrs[:pay_type] = Order::PaymentType::COD
    assert_difference('Order.count', 2) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
  end
  
  test 'should split big order in three' do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 5
    order_attrs[:pay_type] = Order::PaymentType::COD
    assert_difference('Order.count', 3) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
  end
  
  test 'should create courier order' do
    @order = orders(:two)
    order_attrs = @order.attributes
    assert_difference('Order.count', 1) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
    
    @order = Order.find(flash[:order_id].to_i)
  end
  
  test 'should not split courier order' do
    @order = orders(:two)
    order_attrs = @order.attributes
    order_attrs[:quantity] = 5
    assert_difference('Order.count', 1) do
      post :create, :order => order_attrs, :delivery_time => @delivery_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
  end
  
  test 'courier delivery status' do
    @order = orders(:two)
    @order.external_order_id = nil
    assert_not_nil @order.delivery_status
    assert @order.delivery_status =~ /error/, 'order not promoted to Axiomus error'
  end
  
  test 'should not get history for invalid number (shorter, than 5)' do
    @order = orders(:two)
    @order.phone = 'asba2sdfa23asdf9as*%&'
    assert_nil OrdersController.get_phone_history(@order)
  end
  
end
