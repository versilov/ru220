class ExtraPost2LineItem < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site + '/orders/:order_id/'
  self.user = 'stas.versilov@gmail.com'
  self.password = '1234567'

  self.element_name = "line_item"
end