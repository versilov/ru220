# encoding: utf-8


class RobokassaController < ApplicationController
  skip_before_filter :authorize, 
  
  MERCH_PASS1 = 'electricity88'
  MERCH_PASS2 = 'electricity88'
  
  def result
    if check_crc(params, MERCH_PASS2)
      order_id = params[:InvId]
      sum = params[:OutSum].to_i
      order = Order.find(order_id)
      if order
        if order.total_price == sum
          render :text => "OK#{order_id}"
          order.mark_payed
        else
          render :text => "Sum for the order #{order_id} should be #{order.total_price}, but was #{sum}"
        end
      else
        render :text => "Order with id #{order_id} not found."
      end
    else
      render :text => "Bad signature"
    end
  end


  def success
    if check_crc(params, MERCH_PASS1)
      order_id = params[:InvId]
      sum = params[:OutSum].to_i
      order = Order.find(order_id)
      if order 
        if order.total_price == sum
          @message = "Оплата прошла успешно. Заказ будет отправлен вам в течении 24-х часов."
        else
          @message = "Сумма для заказа #{order_id} должна быть равна #{order.total_price}, вместо этого была равна #{sum}."
        end
      else
        @message = "Заказ с номером #{order_id} не найден."
      end
    else
      @message = "Ошибка в подписи запроса."
    end
  end

  def fail
    order_id = params[:InvId]
    @message = "Вы отказались от оплаты заказа №#{order_id}. Заказ отменён."
  end
  
private
  def check_crc(params, pass)
    out_sum = params[:OutSum]
    inv_id = params[:InvId]
    crc = params[:SignatureValue]
    
    crc = crc.upcase
    my_crc = Digest::MD5.hexdigest("#{out_sum}:#{inv_id}:#{pass}").upcase
    return crc == my_crc
  end

end
