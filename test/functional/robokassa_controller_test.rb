require 'test_helper'

class RobokassaControllerTest < ActionController::TestCase
  test "should get result" do
    get :result, :OutSum => '2500', :InvId => '1', :SignatureValue => 'abcdef'
    assert_response :success
  end

  test "should get success" do
    get :success, :OutSum => '2500', :InvId => '1', :SignatureValue => 'abcdef'
    assert_response :success
  end

  test "should get fail" do
    get :fail, :InvId => '1'
    assert_response :success
  end

end
