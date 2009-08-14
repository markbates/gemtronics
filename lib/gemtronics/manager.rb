module Gemtronics
  class Manager
    include Singleton
    
    # A Hash of the default options that are applied to all the gems.
    # These options can be overidden at both the group and the individual
    # gem level.
    GLOBAL_DEFAULT_OPTIONS = {:load => true, :version => '>=0.0.0', :source => 'http://gems.rubyforge.org'}
    
    # A Hash of all the groups that have been defined.
    attr_accessor :groups
    
    def initialize # :nodoc:
      reset!
    end
    
    # Creates, or reopens a new group of gems. It takes the name of the 
    # group, and any options you would like all of the gems in that group 
    # to inherit.
    # 
    # Example:
    #   group(:development, :source => 'http://gems.example.com') do |g|
    #     g.add('gem1')
    #     g.add('gem2')
    #   end
    # 
    # For more information see Gemtronics::Grouper
    def group(name, options = {})
      name = name.to_sym
      options = GLOBAL_DEFAULT_OPTIONS.merge(options)
      g = (self.groups[name] ||= Gemtronics::Grouper.new(name, options))
      if block_given?
        yield g
      else
        return g
      end
    end
    
    # Aliases one gem group to another group.
    # 
    # Example:
    #   group(:development) do |g|
    #     g.add('gem1')
    #     g.add('gem2')
    #   end
    # 
    #   alias_group :test, :development
    # 
    # The result would be the same as if you had done this:
    # 
    #   group(:development) do |g|
    #     g.add('gem1')
    #     g.add('gem2')
    #   end
    #   group(:test, :dependencies => :development) do |g|
    #   end
    def alias_group(name, src)
      group(name, :dependencies => src)
    end
    
    # Reads in a file and sets up the gems appropriately.
    # The default path is <tt>'<pwd>/config/gemtronics.rb'</tt>
    # 
    # See README for an example file.
    def load(file = File.join(FileUtils.pwd, 'config', 'gemtronics.rb'))
      eval(File.read(file), binding)
    end
    
    # Requires all the gems and the specified files for the group.
    # It will not require any gems that have the <tt>:load</tt>
    # options set to <tt>false</tt>
    # 
    # Example:
    #   group(:default) do |g|
    #     g.add('gem1')
    #     g.add('gem2', :version => '1.2.3')
    #     g.add('gem3', :load => false)
    #     g.add('gem4', :require => 'gem-four')
    #     g.add('gem5', :require => ['gem-five', 'gemfive'])
    #     g.add('gem6', :load => false)
    #   end
    # 
    #   Gemtronics.require_gems(:default)
    # 
    # In this example it would do the following:
    # 
    #   gem('gem1', '>=0.0.0')
    #   require 'gem1'
    #   gem('gem2', '1.2.3')
    #   require 'gem2'
    #   gem('gem4', '>=0.0.0')
    #   require 'gem-four'
    #   gem('gem5', '>=0.0.0')
    #   require 'gem-five'
    #   require 'gemfive'
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
    
    # This will install only the gems in the group that
    # are not currently installed in the system.
    # 
    # Example:
    #   group(:default) do |g|
    #     g.add('gem1')
    #     g.add('gem2', :version => '1.2.3')
    #     g.add('gem3', :load => false)
    #     g.add('gem4', :require => 'gem-four')
    #     g.add('gem5', :require => ['gem-five', 'gemfive'])
    #     g.add('gem6', :load => false, :source => 'http://gems.example.com')
    #   end
    # 
    # Assuming gems <tt>gem3, gem4, gem5</tt> are previously installed:
    # 
    #   Gemtronics.install_gems(:default)
    #   # gem install gem1 --source=http://gems.rubyforge.org
    #   # gem install gem2 --source=http://gems.rubyforge.org --version=1.2.3
    #   # gem install gem6 --source=http://gems.example.com
    def install_gems(group = :default)
      group = self.groups[group.to_sym]
      return if group.nil?
      
      group.gems.each do |g|
        unless gem_installed?(g[:name], g[:version])
          cmd = "gem install #{g[:name]} --source=#{g[:source]}"
          unless g[:version].match(/^(\>\=|\>)/)
            cmd << " --version=#{g[:version]}"
          end
          puts cmd
          system cmd
        end
      end
    end
    
    def install_all_gems # :nodoc:
      self.groups.each do |name, value|
        self.install_gems(name)
      end
    end
    
    def reset! # :nodoc:
      self.groups = {}
    end
    
    private
    def gem_installed?(name, version) # :nodoc:
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
