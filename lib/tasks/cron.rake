desc "This task is called by the Heroku cron add-on"
task :cron => :environment do
  puts "Running cron hourly task"
  # Check for status updates for orders
  Order.where('sent_at ISNULL OR payed_at ISNULL').each do |o|
    o.update_sent_and_payed_attributes
  end

  puts "Done [running cron hourly task]"
end
