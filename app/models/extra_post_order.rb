# encoding: utf-8

class ExtraPostOrder < Order
  def post_order
    if self.external_order_id
      PostOrder.find(self.external_order_id.to_i)
    else
      nil
    end
  end
  
  # Was order sent towards client? (i.e. sent_at time has value)
  def sent?
    self.external_order_id and self.post_order.batch != nil
  end
  
  # Return the time of order departure towards client
  # If this field is nil, then sent_at attribute of remote
  # delivery service object is requested and copied to the local object.
  # At last, nil is returned if sent_at is not set even in the remote object
  def sent_at
    if read_attribute(:sent_at)
      return read_attribute(:sent_at)
    else
      if self.post_order.batch
        write_attribute(:sent_at, self.post_order.batch.sending_date)
      else
        return nil
      end
    end
  end
  
  def send_to_delivery
    po = PostOrder.new
    po.index = self.index
    po.region = self.region
    po.area = self.area
    po.city = self.city
    po.address = self.address
    po.addressee = self.client
    po.mass = self.total_quantity*0.2
    
    if self.pay_type == Order::PaymentType::ROBO
      po.value = 1.0
      po.payment = 0.0
    elsif  self.pay_type == Order::PaymentType::COD
      po.value = po.payment = self.total_price
    else
      raise "Неизвестный тип оплаты: #{self.pay_type}"
    end
    
    po.comment = "РБЛ#{self.id}"
    
    if po.save
      self.update_attribute(:external_order_id, po.id)
      self.add_event "Передан в ЭкстраПост под номером #{po.id} (#{po.comment})"
    else
      return false
    end
  end
  
  def post_num
    begin
      self.post_order.num
    rescue Exception
      nil
    end
  end
  
  def get_post_history
    post_params = { 'PATHCUR' => 'rp/servise/ru/home/postuslug/trackingpo',
      'PATHWEB' =>'RP/INDEX/RU/Home',
      'PATHPAGE' => 'RP/INDEX/RU/Home/Search',
      'searchsign' => '1',
      'BarCode' => self.post_num, 
      'searchbarcode' => 'Найти'  }
      
    headers = {
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 
      'User-Agent' => 'Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.30 (KHTML, like Gecko) Ubuntu/11.04 Chromium/12.0.742.112 Chrome/12.0.742.112 Safari/534.30',
      'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.3',
      'Accept-Encoding' => 'gzip,deflate,sdch',
      'Accept-Language' => 'en-US,en;q=0.8',
      'Cache-Control' => 'max-age=0',
      'Connection' => 'keep-alive',
      'Content-Length' => '311',
      'Content-Type' => 'application/x-www-form-urlencoded',
      'Host' => 'russianpost.ru',
      'Origin' => 'http://russianpost.ru',
      'Referer' => 'http://russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo' }

    
    req = Net::HTTP::Post.new(
      '/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo', 
      headers)
    req.form_data = post_params
    resp = Net::HTTP.start('russianpost.ru') {|http|
      http.request(req)
    }
    
      
    doc = Nokogiri::HTML(resp.body)
    doc.css('table.pagetext').first
  end
  

end
