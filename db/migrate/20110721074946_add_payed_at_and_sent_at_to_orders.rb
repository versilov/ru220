class AddPayedAtAndSentAtToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :payed_at, :timestamp
    add_column :orders, :sent_at, :timestamp
  end

  def self.down
    remove_column :orders, :sent_at
    remove_column :orders, :payed_at
  end
end
