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
      g = (self.groups[name] ||= Gemtronics::Grouper.new(options))
      yield g if block_given?
    end
    
    def alias_group(name, src)
      group(name, :dependencies => src)
    end
    
    def load(file = File.join(FileUtils.pwd, 'config', 'gemtronics.rb'))
      eval(File.read(file), binding)
    end
    
    def require_gems(group = :default, options = {})
      group = self.groups[group.to_sym]
      return if group.nil?
      options = {:verbose => false}.merge(options)
      group.gems.each do |g|
        if g[:load] == true
          gem(g[:name], g[:version])
          g[:require].each do |f|
            puts "require #{f}" if options[:verbose]
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
