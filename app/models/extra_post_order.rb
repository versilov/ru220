class ExtraPostOrder < Order
  def post_order
    PostOrder.find(self.external_order_id.to_i)
  end
  
  # Was order sent towards client? (i.e. sent_at time has value)
  def sent?
    self.post_order.batch != nil
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

end
