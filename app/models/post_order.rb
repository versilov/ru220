class PostOrder < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site
  self.user = 'clearsky'
  self.password = 'T7ilk20doZ'
  
  def batch
    if not self.batch_id
      nil
    else
      Batch.find(self.batch_id)
    end
  end
  
end
