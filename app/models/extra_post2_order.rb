class ExtraPost2Order < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site
  self.user = 'stas.versilov@gmail.com'
  self.password = '1234567'

  self.element_name = "order"


  # Return Russian Post parcel num
  def num
    
  end
  

  # These are legacy methods for backwards compatibility, to be reworked later
  def batch
    return nil
    
    if not self.batch_id
      nil
    else
      Batch.find(self.batch_id)
    end
  end
  
  def payment
    # PostPayment.find(:first, :params => { :post_order_id => self.id })
    nil
  end  
end
