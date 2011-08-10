# encoding: utf-8

class ExtraPostOrder < Order
  def post_order
    begin
      PostOrder.find(self.external_order_id.to_i)
    rescue ActiveResource::ResourceNotFound
      return nil
    end
  end
  
  # Was order sent towards client? (i.e. sent_at time has value)
  def sent?
      self.post_order and self.post_order.batch != nil
  end
  
  # Return the time of order departure towards client
  # If this field is nil, then sent_at attribute of remote
  # delivery service object is requested and copied to the local object.
  # At last, nil is returned if sent_at is not set even in the remote object
  def sent_at
    sa = read_attribute(:sent_at)
    if sa
      return sa
    else
      if self.post_order && self.post_order.batch
        sa = self.post_order.batch.sending_date
        update_attribute(:sent_at, sa)
        
        # Send notification email
        if self.email
          begin
            Postman.sent_order_email(self).deliver
          rescue
            print "\n====Email sending error====\n"
          end
        end
        
        return sa
      else
        return nil
      end
    end
  end
  

  def cancel
    if self.sent?
      return false
    else
      epo = self.post_order
      if epo
        epo.destroy
        self.update_attribute(:external_order_id, nil)
      end
      self.update_attribute(:canceled_at, Time.now())
      true
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
    po.mass = self.total_quantity*(0.001*(223+rand(10)))
    
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
      
      # Add line items
      self.line_items.each do |li|
        pli = PostLineItem.new
        pli.post_order_id = po.id
        pli.quantity = li.quantity
        pli.product_sku = 'sd002'
        pli.price = li.product.price
        pli.save
      end
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
  
  def status
    if self.canceled?
      return "Отменён"
    elsif self.post_order
      begin
        st = ''
        if self.sent?
          st = 'Отправлен'
        else
          st = 'Ожидает отправки'
        end
        st += ', Оплачен' if self.payed?
        return st
      rescue Exception
        STDERR.puts "Order #{self} without a corresponding post_order object in extrapost system."
        return "Не найден сопутствующий объект в системе ЭкстраПочта"
      end
    else
      return 'Отсутствует связанный заказ в системе ЭкстраПочта'
    end
  end

end
