class PostOrder < ActiveResource::Base
  self.site = Rails.application.config.extrapost_site
  self.user = 'clearsky'
  self.password = 'T7ilk20doZ'
  
  def batch
    Batch.find(self.batch_id)
  end
end
