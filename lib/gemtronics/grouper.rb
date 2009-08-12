module Gemtronics
  class Grouper
    attr_accessor :gems
    attr_accessor :group_options
    
    def initialize(options = {})
      self.gems = []
      deps = options.delete(:dependencies)
      if deps
        [deps].flatten.each do |dep|
          self.dependency(dep)
        end
      end
      self.group_options = options
      self
    end
    
    def add(name, options = {})
      g = Gemtronics::Manager::GLOBAL_DEFAULT_OPTIONS.merge(self.group_options.merge({:name => name.to_s, :require => [name.to_s]}.merge(options)))
      g[:require] = [g[:require]].flatten
      self.gems << g
    end
    
    def remove(name)
      self.gems.each do |g|
        if g[:name] = name.to_s
          self.gems.delete(g)
          break
        end
      end
    end
    
    def dependency(name)
      group = Gemtronics::Manager.instance.groups[name.to_sym]
      if group
        self.gems << group.gems.dup
        self.gems.flatten!
      end
    end
    
  end # Grouper
end # Gemtronics
