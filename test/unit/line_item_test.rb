require 'test_helper'

class LineItemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "should create sd02 line item" do
    order = orders(:one)
    
    order.create_sd02_line_item(3)
    line_item = order.line_items.first
    
    assert_not_nil line_item
    assert_equal 3, line_item.quantity
    assert_equal order, line_item.order
  end
end
