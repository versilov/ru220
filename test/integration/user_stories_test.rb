# encoding: utf-8

require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :all
  
  def login(login, password)
    get '/login'
    post_via_redirect '/login', :login => login, :password => password
    assert_response :success
    assert_template 'orders/index'
    assert_not_nil session[:user_id]
    User::find_by_id(session[:user_id])
  end

  test "place an order" do
    LineItem.delete_all
    Order.delete_all
    
    get '/'
    assert_response :success
    assert_template 'articles/home'
    
    post_via_redirect '/orders', :order => { :client => 'Вася Тестер',
                                :index => 443099,
                                :region => 'Самарская обл.',
                                :area => '',
                                :city => 'Самара',
                                :address => 'ул. Ленина, д. 12, кв. 23',
                                :phone => '+7 916 234 09 23',
                                :email => 'vasya@tester.org',
                                :pay_type => Order::PaymentType::COD,
                                :delivery_type => Order::DeliveryType::POSTAL,
                                :quantity => 3 },
                        :delivery_time => {
                                :"date(1i)" => 2011,
                                :"date(2i)" => 8,
                                :"date(3i)" => 8,
                                :from => 13, :to => 17, 
                                :city => 'Санкт-Петербург' }
                                
                                
    assert_response :success
    assert_template 'done'
    
    assert_equal 1, Order.all.size  # Just one order should be
    
    assert_not_nil flash[:order_id]
    order = Order.find_by_id(flash[:order_id])
    assert_not_nil order
    
    assert_equal 3, order.total_quantity
    assert_equal 'Вася Тестер', order.client
    assert_equal 443099, order.index
    assert_equal 'Самарская обл.', order.region
    assert_equal '', order.area
    assert_equal 'Самара', order.city
    assert_equal 'ул. Ленина, д. 12, кв. 23', order.address
    assert_equal '+7 916 234 09 23', order.phone
    assert_equal 'vasya@tester.org', order.email
    assert_equal Order::PaymentType::COD, order.pay_type
    
    assert_equal 1, order.line_items.size
    line_item = order.line_items[0]
    assert_equal products(:sd02), line_item.product
  end
  
  test 'viewing orders list' do
    user = login 'dave', 'secret'
    assert_not_nil user
    
    get '/orders'
    assert_response :success
    assert_template 'orders/index'
  end
  
  test 'show order' do
    user = login 'dave', 'secret'
    assert_not_nil user
    
    get '/orders'
    assert_response :success
    assert_template 'orders/index'
    
    get "/orders/#{orders(:one).id}"
    assert_response :success
    assert_template 'orders/show'
  end
end
















