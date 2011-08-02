module OrdersHelper
  def delivery_dates
    weekdays = I18n.t 'date.standalone_day_names'
    start_day = Date.tomorrow.ajd.to_i + 1
    end_day = start_day + 8
    (start_day..end_day).reject { |d| Date.new!(d).wday == 0 }.collect { |d| [ l(Date.new!(d), :format => :long) + ' ' + weekdays[Date.new!(d).wday], d.to_s] }
  end
end
