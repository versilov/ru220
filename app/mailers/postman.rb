# encoding: utf-8

class Postman < ActionMailer::Base
  default :from => "Магазин Энергосбережения 220РУ <energo220ru@gmail.com>"

  def new_order_email(order)
    @order = order
    mail(:to => order.email,
         :subject => "Заказ энергосберегателя №#{order.id} принят")
  end

  def sent_order_email(order)
    @order = order
    mail(:to => order.email,
      :subject => "Заказ энергосберегателя №#{order.id} ОТПРАВЛЕН")
    end
end
