class ExtraPostOrder < ActiveRecord::Base
  belongs_to :order
  belongs_to :post_order
end
