module Gemtronics
  class Definition < Hash
    
    [:name, :version, :source, :load].each do |meth|
      define_method(meth) do
        return self.fetch(meth)
      end
      define_method("#{meth}=") do |x|
        self.store(meth, x)
      end
    end
    
    def require_list
      return self.fetch(:require)
    end
    
    def require_list=(x)
      self.store(:require, x)
    end
    
  end # Definition
end # Gemtronics