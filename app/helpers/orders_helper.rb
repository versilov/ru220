module OrdersHelper
  def delivery_dates
    weekdays = I18n.t 'date.standalone_day_names'
    start_day = Date.tomorrow.jd + 1
    end_day = start_day + 8
    (start_day..end_day).reject { |d| Date::jd(d).wday == 0 }.collect { |d| [ l(Date::jd(d), :format => :long) + ' ' + weekdays[Date::jd(d).wday], d.to_s] }
  end
  
  def order_row_class(order)
    if order.payed_at
      "delivered"
    elsif order.has_errors?
      "errorneus"
    elsif order.sent_at
      "sent_order"
    elsif order.canceled_at
      "canceled"
    else
      ""
    end
  end
end
