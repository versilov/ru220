# encoding: utf-8

class ExtraPostOrder < Order
  def post_order
    if (not self.external_order_id) || (self.external_order_id.length == 0)
      return nil
    end
    
    begin
      PostOrder.find(self.external_order_id.to_i)
    rescue ActiveResource::ResourceNotFound
      return nil
    end
  end
  
  # Was order sent towards client? (i.e. sent_at time has value)
  def sent?
      self.sent_at != nil
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
        self.add_event :date => sa, :description => "Отправлен #{sa}"
        
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
  
  def payed_at
    pa = read_attribute(:payed_at)
    if pa
      return pa
    else
      if self.post_order && self.post_order.payment
        payment = self.post_order.payment
        pa = payment.date
        update_attribute(:payed_at, pa)
        self.add_event :date => pa, :description => "Оплачено #{payment.sum} руб., №#{payment.num}, КГП #{payment.kgp}"
        
        return pa
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
    if self.external_order_id
      return true # Already registered in external delivery system.
    end
    
    po = create_post_order(self.total_quantity, self.line_items[0].product)
    
    if po
      self.update_attribute(:external_order_id, po.id)
      self.add_event "Передан в ЭкстраПост под номером #{po.id} (#{po.comment})"
      return true
    else
      self.add_event "Не удалось передать заказ в ЭкстраПост."
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
      'Host' => 'www.russianpost.ru',
      'Origin' => 'http://www.russianpost.ru',
      'Referer' => 'http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo' }

    
    req = Net::HTTP::Post.new(
      '/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo', 
      headers)
    req.form_data = post_params
    
    
    resp = Net::HTTP.start('www.russianpost.ru') { |http|
      http.request(req)
    }
    
      
    doc = Nokogiri::HTML(resp.body)
    doc.css('table.pagetext').first
  rescue SocketError
      STDERR.puts "Could not reach www.russianpost.ru"
      return ""
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

  
private

  # create post order with the given quantity
  # of the product
  def create_post_order(quantity, product)
    po = PostOrder.new
    po.index = self.index
    po.region = self.region
    po.area = self.area
    po.city = self.city
    po.address = self.address
    po.addressee = self.client
    po.mass = 0.001*(quantity*200+24+rand(10))

    if self.pay_type == Order::PaymentType::ROBO
      po.value = 1.0
      po.payment = 0.0
    elsif  self.pay_type == Order::PaymentType::COD
      po.value = po.payment = product.price*quantity
    else
      raise "Неизвестный тип оплаты: #{self.pay_type}"
    end
    
    po.comment = "РБЛ#{self.id}"
    
    begin
      
      if po.save
        
        # Add line item
        pli = PostLineItem.new
        pli.post_order_id = po.id
        pli.quantity = quantity
        pli.product_sku = product.sku
        pli.price = product.price
        pli.save
        
        po
      else
        return nil
      end
    
    rescue => bang
      STDERR.puts "Error in extra_post.save: " + bang.backtrace.join("\n")
      return nil
    end
  end

end
