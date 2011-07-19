require 'test_helper'

class RobokassaControllerTest < ActionController::TestCase
  OUT_SUM = '5964.0'
  
  setup do
    @order = orders(:one)
  end
  
  test "should get result" do
    crc = Digest::MD5.hexdigest("#{OUT_SUM}:#{@order.id}:#{RobokassaController::MERCH_PASS2}").upcase
    get :result, :OutSum => OUT_SUM, :InvId => @order.id, :SignatureValue => crc
    assert_response :success
  end

  test "should get success" do
    crc = Digest::MD5.hexdigest("#{OUT_SUM}:#{@order.id}:#{RobokassaController::MERCH_PASS1}").upcase

    get :success, :OutSum => OUT_SUM, :InvId => @order.id, :SignatureValue => crc
    assert_response :success
  end

  test "should get fail" do
    get :fail, :InvId => @order.id
    assert_response :success
  end

end
