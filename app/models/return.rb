class Return < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site
  self.user = 'clearsky'
  self.password = 'T7ilk20doZ'
  
  def order
     po = PostOrder.find(self.post_order_id)
     Order.find_by_external_order_id(po.id.to_s)
   rescue
     nil
  end
end
