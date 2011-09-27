desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  puts "Running cron hourly task"
  # 1. Check for status updates for orders
  
  # 2. Send orders for the last 3 days without external id to delivery services
  Order.last_n_days(3).where(:external_order_id => nil).each do |o|
  # Don't launch this yet, because problem was in quotes in XML attributes,
  # not in unresponding axiomus.
  # And also we won't be able to re-send order to axiomus, cuz delivery
  # time interval is not saved in the order.
  #  o.send_to_delivery
  end
  
  puts "Done [running cron hourly task]"
end
