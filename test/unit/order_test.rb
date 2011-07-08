# encoding: utf-8
require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test 'order attributes must be present' do
    order = Order.new
    assert order.invalid?
    assert order.errors[:index].any?
    assert order.errors[:city].any?
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
    assert_equal 'недостаточной длины (не может быть меньше 6 символов)', order.errors[:index][0]
    assert_equal 'должен содержать только цифры', order.errors[:index][1]
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
end
