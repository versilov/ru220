require 'test_helper'
require './config/routes.rb'

class RoutingTest < ActionController::TestCase

  test "root path is order->new" do
    assert_recognizes({:controller => 'orders', :action => 'new'}, '/')
  end
end
