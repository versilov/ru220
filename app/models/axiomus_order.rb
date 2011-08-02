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
    uid = 92
    date = @date
    start_time = @from + ':00'
    end_time = @to + ':00'
    cache = 'yes'
    cheque = 'yes'
    selsize = 'no'
    checksum_source = "#{uid}1#{self.total_quantity}#{self.total_price.to_i}#{date} #{start_time}#{cache}/#{cheque}/#{selsize}"
    puts "Checksum source: #{checksum_source}"
    checksum = Digest::MD5.hexdigest(checksum_source)
    xml = %{<?xml version='1.0' standalone='yes'?>
<singleorder>
<mode>new</mode>
<auth ukey="XXcd208495d565ef66e7dff9f98764XX" checksum="#{checksum}" />
<order inner_id="#{self.id}" name="#{self.client}"  address="#{self.city}, #{self.address}" from_mkad="0" d_date="#{date}" b_time="#{start_time}" e_time="#{end_time}">
   <contacts>тел. #{self.phone}</contacts>
   <description></description>
   <hidden_desc></hidden_desc>
   <services cash="#{cache}" cheque="#{cheque}" selsize="#{selsize}" />
   <items>
		<item name="Энергосберегатель"  weight="0.200" quantity="#{self.total_quantity}" price="#{self.line_items[0].product.price}" />
   </items>
</order>
</singleorder>}
    puts xml
    url = URI.parse('http://www.axiomus.ru/test/api_xml_test.php')
    post_params = { 'data' => xml }
    resp = Net::HTTP.post_form(url, post_params)
    
    puts resp.body
    
    doc = REXML::Document.new(resp.body)
    
    if doc.elements['response/status'].attributes['code'].to_i > 0
      return false
    else
      self.update_attribute(:external_order_id, doc.elements['response/auth'].text)
      self.add_event "Передан в Аксиомус под номером #{doc.elements['response/auth'].attributes['objectid']}"
      return true
    end
  end
end
