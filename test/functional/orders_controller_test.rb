# encoding: utf-8

require 'test_helper'

class OrdersControllerTest < ActionController::TestCase
  setup do
    @order = orders(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:orders)
    
    assert_select 'h1', 'Заказы'
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create order" do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 3
    assert_difference('Order.count') do
      post :create, :order => order_attrs
    end
    assert_redirected_to done_url
    assert flash[:order_id] > 0, "order id is promoted to next page (done)"
  end
  
  test "should create order with errors" do
    order_attrs = @order.attributes
    order_attrs[:quantity] = 3
    order_attrs[:index] = 123456
    assert_no_difference('Order.count') do
      post :create, :order => order_attrs
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

  test "should destroy order" do
    assert_difference('Order.count', -1) do
      delete :destroy, :id => @order.to_param
    end

    assert_redirected_to orders_path
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
end
