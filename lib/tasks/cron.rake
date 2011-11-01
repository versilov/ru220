# encoding: utf-8

desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  puts "Running cron hourly task"
  # Check for status updates for orders
  Order.where('sent_at ISNULL OR payed_at ISNULL').each do |o|
    o.update_sent_and_payed_attributes
  end
  
  # Check for fresh returns (for the last 3 hours)
  Return.where('created_at >= ?', 2.hours.ago).each do |ret|
    order = ret.order
    if order
      order.update_attribute(:returned_at, ret.created_at)
      order.add_event :description => 'Возврат', :date => ret.created_at
    end
  end

  puts "Done [running cron hourly task]"
end
