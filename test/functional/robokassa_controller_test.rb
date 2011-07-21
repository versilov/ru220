require 'test_helper'

class RobokassaControllerTest < ActionController::TestCase

  
  setup do
    @order = orders(:one)
    @order.create_sd02_line_item(3)
  end
  
  test "should get result" do
    crc = Digest::MD5.hexdigest("#{@order.total_price}:#{@order.id}:#{RobokassaController::MERCH_PASS2}").upcase
    get :result, :OutSum => @order.total_price, :InvId => @order.id, :SignatureValue => crc
    assert_response :success
    @order = Order.find(@order.id)
    p @order
    assert @order.payed?
  end

  test "should get success" do
    crc = Digest::MD5.hexdigest("#{@order.total_price}:#{@order.id}:#{RobokassaController::MERCH_PASS1}").upcase

    get :success, :OutSum => @order.total_price, :InvId => @order.id, :SignatureValue => crc
    assert_response :success
  end

  test "should get fail" do
    get :fail, :InvId => @order.id
    assert_response :success
  end

end
