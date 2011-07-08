class CreateDeliveryLimits < ActiveRecord::Migration
  def self.up
    create_table :delivery_limits, :id => false do |t|
      t.string :index,      :limit => 6
      t.string :opsname,    :limit => 100
      t.date :actdate
      t.date :prbegdate
      t.date :prenddate
      t.string :delivtype,  :limit => 30
      t.string :delivpnt,   :limit => 100
      t.string :baserate
      t.string :basecoeff
      t.string :transfcnt
      t.string :ratezone
      t.date :cfactdate
      t.string :delivindex, :limit => 6
    end
  end

  def self.down
    drop_table :delivery_limits
  end
end
