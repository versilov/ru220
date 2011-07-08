# encoding: utf-8

require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "place an order" do
    LineItem.delete_all
    Order.delete_all
    
    get '/'
    assert_response :success
    assert_template 'new'
    
    post_via_redirect '/orders', :order => { :client => 'Вася Тестер',
                                :index => 443096,
                                :region => 'Самарская обл.',
                                :area => '',
                                :city => 'Самара',
                                :address => 'ул. Ленина, д. 12, кв. 23',
                                :phone => '+7 916 234 09 23',
                                :email => 'vasya@tester.org',
                                :pay_type => Order::PaymentType::COD,
                                :quantity => 3 }
                                
                                
    assert_response :success
    assert_template 'done'
    
    assert_equal 1, Order.all.size  # Just one order should be
    
    assert_not_nil flash[:order_id]
    order = Order.find_by_id(flash[:order_id])
    assert_not_nil order
    
    assert_equal 3, order.total_quantity
    assert_equal 'Вася Тестер', order.client
    assert_equal 443096, order.index
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
end
