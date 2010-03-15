module JekyllHelper
  JK_FLASH_NAMES = [:notice, :error].freeze unless self.class.const_defined? "JK_FLASH_NAMES"
  JK_MONTH = {1 => 'Jan.',
           2 => 'Feb.',
           3 => 'March',
           4 => 'April',
           5 => 'May',
           6 => 'June',
           7 => 'July',
           8 => 'Aug.',
           9 => 'Sept.',
           10 => 'Oct.',
           11 => 'Nov.',
           12 => 'Dec.'
           }.freeze unless self.class.const_defined? "JK_MONTH"

  def flash_messages
    message_string = ""
    for name in JK_FLASH_NAMES
      if flash[name]
          message_string += "<br /><div id=\"flash#{name}\">#{flash[name]}</div><br />"
      end
      flash[name] = nil
    end
    return message_string
  end

  def ap_time(date)
    hour = date.hour
    minute = sprintf("%02.f", date.min)
    if hour > 11
      hour = hour-12
      hour = 12 if hour == 0
      hour.to_s+":"+minute.to_s+" p.m."
    else
      hour = 12 if hour == 0
      hour.to_s+":"+minute.to_s+" a.m."
    end
  end
  
  def ap_date(date)
    if date
      JK_MONTH[date.month].to_s+" "+date.day.to_s+", "+date.year.to_s
    end
  end
  
  def ap_date_time(date)
    ap_date(date)+" "+ap_time(date)
  end
  
end