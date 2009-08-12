module Gemtronics
  class Manager
    include Singleton
    
    GLOBAL_DEFAULT_OPTIONS = {:load => true, :version => '>=0.0.0', :source => 'http://gems.rubyforge.org'}
    
    attr_accessor :groups
    
    def initialize
      reset!
    end
    
    def group(name, options = {})
      name = name.to_sym
      options = GLOBAL_DEFAULT_OPTIONS.merge(options)
      yield self.groups[name] ||= Gemtronics::Grouper.new(options)
    end
    
    def load(file)
      eval(File.read(file), binding)
    end
    
    def require_gems(group = :default)
      group = self.groups[group.to_sym]
      return if group.nil?
      
      group.gems.each do |g|
        if g[:load] == true
          gem(g[:name], g[:version])
          g[:require].each do |f|
            require f
          end
        end
      end
    end
    
    def install_gems(group = :default)
      group = self.groups[group.to_sym]
      return if group.nil?
      
      group.gems.each do |g|
        unless gem_installed?(g[:name], g[:version])
          cmd = "gem install #{g[:name]} --source=#{g[:source]}"
          unless g[:version].match(/^(\>\=|\>)/)
            cmd << " --version=#{g[:version]}"
          end
          system cmd
        end
      end
    end
    
    def install_all_gems
      self.groups.each do |name, value|
        self.install_gems(name)
      end
    end
    
    def reset!
      self.groups = {}
    end
    
    def gem_installed?(name, version)
      begin
        gem(name, version)
        return true
      rescue Gem::LoadError => e
        return true if e.message.match(/can't activate/)
        return false
      end
    end
    
  end # Manager
end # Gemtronics
