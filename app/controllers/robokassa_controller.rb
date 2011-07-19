# encoding: utf-8


class RobokassaController < ApplicationController
  skip_before_filter :authorize, 
  
  MERCH_PASS1 = 'electricity88'
  MERCH_PASS2 = 'electricity88'
  
  def result
    if check_crc(params, MERCH_PASS2)
      order_id = params[:InvId]
      order = Order.find(order_id)
      if order
        render :text => "OK#{order_id}" 
        # TODO: Mark order as payed.
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
      order = Order.find(order_id)
      if order 
        render :text => "Operation successfull"
      else
        render :text => "Order with id #{order_id} not found"
      end
    else
      render :text => "Bad signature"
    end
  end

  def fail
    order_id = params[:InvId]
    render :text => "Вы отказались от оплаты заказа №#{order_id}"
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
