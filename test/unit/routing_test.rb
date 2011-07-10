require 'test_helper'
require './config/routes.rb'

class RoutingTest < ActionController::TestCase

  test "root path is articles/home" do
    assert_recognizes({:controller => 'articles', :action => 'home'}, '/')
  end
end
