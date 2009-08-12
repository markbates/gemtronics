module Gemtronics
  
  class << self
    
    def method_missing(sym, *args)
      Gemtronics::Manager.instance.send(sym, *args)
    end
    
  end
  
end # Gemtronics