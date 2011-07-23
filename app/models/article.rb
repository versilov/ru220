# encoding: UTF-8
class Article < ActiveRecord::Base
  validates_uniqueness_of :alias
  
  def to_param
    self.alias
  end
end
