# encoding: utf-8

class AxiomusOrder < Order
  def okey
    self.external_order_id
  end
  
  def okey= key
    self.external_order_id = key
  end
  
  def send_to_delivery
    uid = 92
    date = Date.tomorrow
    start_time = '10:00'
    end_time = '18:00'
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
<order inner_id="#{self.id}" name="#{self.client}"  address="#{self.index}, #{self.region}, #{self.city}, #{self.address}" from_mkad="0" d_date="#{date}" b_time="#{start_time}" e_time="#{end_time}">
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
    status = doc.elements['response/status']
    
    self.update_attribute(:external_order_id, doc.elements['response/auth'].text)
   
    response = doc.elements['response']
    
    if response.elements['status'].attributes['code'].to_i > 0
      return false
    else
      self.add_event "Передан в Аксиомус под номером #{response.elements['auth'].attributes['objectid']}"
      return true
    end
  end
end
