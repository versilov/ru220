class AddTypeAndExternalOrderIdToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :type, :string, :default => 'Order', :null => false
    add_column :orders, :external_order_id, :string, :limit => 64, :default => nil
    
#    Order.all.each do |order|
#      if order.axiomus_order
#        order.type = 'AxiomusOrder'
#        order.external_order_id = order.axiomus_order.auth
#        order.save
#        order.axiomus_order.destroy
#      elsif order.extra_post_order
#        order.type = 'ExtraPostOrder'
#        order.external_order_id = order.extra_post_order.post_order_id
#        order.save
#        order.extra_post_order.destroy
#      else
#        puts "Order for #{order.client} without external order. Deleting."
#        order.destroy
#      end
#    end
  end

  def self.down
    remove_column :orders, :external_order_id
    remove_column :orders, :type
  end
end
