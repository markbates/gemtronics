module Gemtronics
  # Represents the definition of a Gem.
  class Definition < Hash
    
    # Get/set the name of the gem.
    attr_accessor :name
    # Get/set the version of the gem. Defaults to <tt>>=0.0.0</tt>
    attr_accessor :version
    # Get/set the source of the gem. Defaults to <tt>http://gems.rubyforge.org</tt>
    attr_accessor :source
    
    # Returns true/false if the gem should be required. Defaults to <tt>true</tt>.
    def load?
      # method built dynamically. This is just a stub for RDoc.
    end
    
    # Set whether the gem should be required.
    def load=(x)
      # method built dynamically. This is just a stub for RDoc.
    end
    
    # Returns true/false if the gem should be installed with ri. Defaults to <tt>false</tt>.
    def ri?
      # method built dynamically. This is just a stub for RDoc.
    end
    
    # Set whether the gem should be installed with ri.
    def ri=(x)
      # method built dynamically. This is just a stub for RDoc.
    end
    
    # Returns an Array of files that should be required. Defaults to <tt>[<name>]</tt>
    def require_list
      return [self.name] unless self.has_key?(:require)
      return [self.fetch(:require)].flatten
    end
    
    # Sets the names of the files that should be required.
    def require_list=(x)
      self.store(:require, [x].flatten)
    end
    
    # Returns <tt><name>-<version></tt>.
    # 
    # Example:
    #   gd = Gemtronics::Definition.new
    #   gd.name = 'configatron'
    #   gd.version = '2.3.0'
    #   gd.to_s #=> 'configatron-2.3.0'
    def to_s
      return "#{self.name}-#{self.version}"
    end
    
    # Generates an install command string.
    # 
    # Example:
    #   gd = Gemtronics::Definition.new
    #   gd.name = 'configatron'
    #   gd.version = '2.3.0'
    #   gd.install_command #=> 'gem install configatron --source=http://gems.rubyforge.org --version=2.3.0'
    def install_command
      cmd = "gem install #{self.name} --source=#{self.source}"
      unless self.ri?
        cmd << ' --no-ri'
      end
      
      unless self.rdoc?
        cmd << ' --no-rdoc'
      end
      
      unless self.version.match(/^(\>\=|\>)/)
        cmd << " --version=#{self.version}"
      end
      return cmd
    end
    
    # Returns <tt>true/false</tt> depending on whether the gem
    # is installed or not.
    def installed?
      begin
        gem(self.name, self.version)
        return true
      rescue Gem::LoadError => e
        return true if e.message.match(/can't activate/)
        return false
      end
    end
    
    # Calls the <tt>gem</tt> method with <tt>name</tt> and <tt>version</tt>.
    # It does NOT do any requiring!
    # 
    # Example:
    #   gd = Gemtronics::Definition.new
    #   gd.name = 'my_gem'
    #   gd.version = '1.2.3'
    #   gd.load_gem # => gem('my_gem', '1.2.3')
    def load_gem
      gem(self.name, self.version)
    end
    
    # Calls the <tt>load_gem</tt> method and then requires each
    # file in the <tt>require_list</tt>
    def require_gem(options = {})
      load_gem
      self.require_list.each do |f|
        puts "require #{f}" if options[:verbose]
        require f
      end
    end
    
    private
    def self.build_method(name, defval = nil, key = name) # :nodoc:
      define_method(name) do
        return defval unless self.has_key?(key)
        return self.fetch(key)
      end
      define_method("#{name.to_s.gsub('?', '')}=") do |x|
        self.store(key, x)
      end
    end
    
    build_method(:name)
    build_method(:version, '>=0.0.0')
    build_method(:source, 'http://gems.rubyforge.org')
    build_method(:load?, true, :load)
    build_method(:ri?, false, :ri)
    build_method(:rdoc?, false, :rdoc)
    
  end # Definition
end # Gemtronics