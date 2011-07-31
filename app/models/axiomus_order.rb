class AxiomusOrder < Order
  def okey
    self.external_order_id
  end
  
  def okey= key
    self.external_order_id = key
  end
end
