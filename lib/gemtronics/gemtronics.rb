module Gemtronics # :nodoc:
  
  class << self
    
    def method_missing(sym, *args) # :nodoc:
      Gemtronics::Manager.instance.send(sym, *args)
    end
    
  end
  
end # Gemtronics