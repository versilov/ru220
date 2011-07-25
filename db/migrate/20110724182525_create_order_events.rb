class CreateOrderEvents < ActiveRecord::Migration
  def self.up
    create_table :order_events do |t|
      t.integer :order_id, :null => false
      t.string :description, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :order_events
  end
end
