class AddReturnedAtToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :returned_at, :datetime
    Return.all.each do |ret|
      order = ret.order
      if order
        order.update_attribute(:returned_at, ret.created_at)
        order.add_event :description => 'Возврат', :date => ret.created_at
      end
    end
  end

  def self.down
    remove_column :orders, :returned_at
  end
end
