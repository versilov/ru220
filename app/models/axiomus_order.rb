# encoding: utf-8

class AxiomusOrder < Order
  
  attr_accessor :date, :from, :to
  
  def okey
    self.external_order_id
  end
  
  def okey= key
    self.external_order_id = key
  end
  
  def send_to_delivery
    uid = Rails.application.config.axiomus_uid
    ukey = Rails.application.config.axiomus_ukey
    axiomus_url = Rails.application.config.axiomus_url
    
    total_SKU = 1 # Just one kind of product
    date = @date
    start_time = @from + ':00'
    end_time = @to + ':00'
    cache = 'yes'
    cheque = 'yes'
    selsize = 'no'
    checksum_source = "#{uid}#{total_SKU}#{self.total_quantity}#{self.total_price.to_i}#{date} #{start_time}#{cache}/#{cheque}/#{selsize}"
    checksum = Digest::MD5.hexdigest(checksum_source)
    xml = %{<?xml version='1.0' standalone='yes'?>
<singleorder>
<mode>new</mode>
<auth ukey="#{ukey}" checksum="#{checksum}" />
<order inner_id="#{self.id}" name="#{self.client}"  address="#{self.city}, #{self.address}" from_mkad="0" d_date="#{date}" b_time="#{start_time}" e_time="#{end_time}">
   <contacts>тел. #{self.phone}</contacts>
   <description></description>
   <hidden_desc></hidden_desc>
   <services cash="#{cache}" cheque="#{cheque}" selsize="#{selsize}" />
   <items>
      <item name="Энергосберегатель"  weight="0.200" quantity="#{self.total_quantity}" price="#{self.line_items[0].product.price}" bundling="1" />
   </items>
</order>
</singleorder>}
    
    puts "XML order for Axiomus:\n#{xml}"

    url = URI.parse(axiomus_url)
    post_params = { 'data' => xml }
    resp = Net::HTTP.post_form(url, post_params)
    
    doc = REXML::Document.new(resp.body)
    
    if doc.elements['response/status'].attributes['code'].to_i > 0
      return false
    else
      self.update_attribute(:external_order_id, doc.elements['response/auth'].text)
      self.add_event "Передан в Аксиомус под номером #{doc.elements['response/auth'].attributes['objectid']}"
      return true
    end
  end
  
  def status
      if not self.external_order_id
        return 'Заказ не передан в Аксиомус (нет идентификатора)'
      end
      xml = %{<?xml version='1.0' standalone='yes'?>
      <singleorder>
        <mode>status</mode>
        <okey>#{self.external_order_id}</okey>
      </singleorder>}
      url = URI.parse(Rails.application.config.axiomus_url)
      post_params = { 'data' => xml }
      resp = Net::HTTP.post_form(url, post_params)
      puts resp
      
      doc = REXML::Document.new(resp.body)
      status = doc.elements['response/status']
      return "#{status.text} (#{status.attributes['code']})"
  end
  
  def delivery_status
    "<span class='error'>Не передан в Аксиомус</span>" if not self.external_order_id
  end
  
 
  def cancel
    raise NotImplementedError
  end
end
