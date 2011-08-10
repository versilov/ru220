class PostLineItem < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site # + 'post_orders/:post_order_id'
  self.user = 'clearsky'
  self.password = 'T7ilk20doZ'
  self.element_name = 'line_item'
end
