# encoding: utf-8
require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test 'order attributes must be present' do
    order = Order.new
    assert order.invalid?
    assert order.errors[:index].any?
    assert order.errors[:address].any?
    assert order.errors[:client].any?
    assert order.errors[:phone].any?
    
    # These attributes are not required.
    assert order.errors[:email].none?
    assert order.errors[:region].none?
    assert order.errors[:area].none?
  end
  
  test 'order index must have 6 digits' do
    order = orders(:one)
    assert order.valid?
    
    order.index = 123
    assert order.invalid?
    assert order.errors[:index].any?
    
    order.index = 1234567
    assert order.invalid?
    assert order.errors[:index].any?
    
    order.index = '123abc'
    assert order.invalid?
    assert order.errors[:index].any?
    
    order.index = 443110
    assert order.valid?
    assert order.errors[:index].none?
  end
  
  test 'order postal index must contain only digits' do
    order = orders(:one)
    order.index = '123abc'
    
    assert !order.save
    assert_equal 'неверной длины (может быть длиной ровно 6 символа)', order.errors[:index][0]
    assert_equal 'не найден', order.errors[:index][1]
  end
  
  test 'post index must exist' do
    order = orders(:one)
    assert order.valid?
    
    order.index = 123456
    assert order.invalid?
    assert_equal 'не найден', order.errors[:index][0]
  end
  
  test 'index delivery limit' do
    order = orders(:one)
    assert order.valid?
    
    order.index = 157164
    assert order.invalid?
    assert_equal 'закрыт до 31-12', order.errors[:index][0]
  end
  
  test 'should mark as payed' do
    order = orders(:one)
    assert order.valid?
    
    order.mark_payed
    assert order.valid?
    assert order.save
    order.reload
    assert order.payed?
  end
  
  test 'city!' do
    order = orders(:moscow)
    assert order.valid?
    
    assert_equal '', order.city
    assert_equal 'МОСКВА', order.city!
    assert_equal 'МОСКВА', order.region
  end
  
  test 'add_event' do
    order = orders(:one)
    assert_difference('OrderEvent.count', 1) do
      order.add_event "Something"
      assert_equal "Something", order.order_events.last.description
      assert_equal Date.today, order.order_events.last.created_at.to_date
    end
    
    assert_difference('OrderEvent.count', 1) do
      order.add_event :date => "08-08-2008", :description => "Nothing"
      assert_equal "Nothing", order.order_events.last.description
      assert_equal "08-08-2008".to_date, order.order_events.last.created_at.to_date
    end
  end
end
