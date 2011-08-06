# encoding: utf-8

require 'test_helper'

class PostmanTest < ActionMailer::TestCase
  setup do
    @order = orders(:one)
  end
  test "new_order_email" do
    mail = Postman.new_order_email(@order)
    assert_equal "Заказ энергосберегателя №#{@order.id} принят", mail.subject
    assert_equal [@order.email], mail.to
    assert_equal ["energo220ru@gmail.com"], mail.from
    assert_match "Ваш заказ энергосберегателя №#{@order.id} принят", mail.body.encoded
  end

  test "sent_order_email" do
    mail = Postman.sent_order_email(@order)
    assert_equal "Заказ энергосберегателя №#{@order.id} ОТПРАВЛЕН", mail.subject
    assert_equal [@order.email], mail.to
    assert_equal ["energo220ru@gmail.com"], mail.from
    assert_match "Ваш заказ энергосберегателя №#{@order.id} отправлен", mail.body.encoded
  end

end
