module Gemtronics
  class Manager
    include Singleton
    
    # A Hash of the default options that are applied to all the gems.
    # These options can be overidden at both the group and the individual
    # gem level.
    GLOBAL_DEFAULT_OPTIONS = {:load => true, :version => '>=0.0.0', :source => 'http://gems.rubyforge.org', :ri => false, :rdoc => false}
    
    # A Hash of all the groups that have been defined.
    attr_accessor :groups
    attr_accessor :installed_gems # :nodoc:
    
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
      g = (self.groups[name] ||= Gemtronics::Grouper.new(name, options || {}))
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
        if g.load? == true
          g.require_gem(options)
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
      if group == 'everything!'
        install_all_gems
        return
      end
      group = self.groups[group.to_sym]
      return if group.nil?
      
      group.gems.each do |g|
        unless gem_installed?(g)
          cmd = g.install_command
          puts cmd
          system cmd
          self.installed_gems << g.to_s
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
      self.installed_gems = []
    end
    
    # Finds and returns a Gemtronics::Definition for the specified
    # gem, if one exists.
    # 
    # Search Order:
    # If the option <tt>:group</tt> is passed in it will search
    # only within that group.
    # 
    # If <tt>RAILS_ENV</tt> is defined it will search in the group
    # that matches the current Rails environment
    # 
    # Finally it will search all gems and return the first one it
    # finds. There is no guarantee as to the order it searches through
    # the groups.
    # 
    #   Gemtronics.find('gem1')
    #   Gemtronics.find('gem1', :group => :production)
    def find(name, options = {})
      group = options[:group]
      if group
        group = self.groups[group.to_sym]
        return nil if group.nil?
        gemdef = group.search(name, options)
        return gemdef unless gemdef.nil?        
      elsif defined?(RAILS_ENV)
        return find(name, {:group => RAILS_ENV.to_sym}.merge(options))
      else
        self.groups.each do |key, group|
          gemdef = group.search(name, options)
          return gemdef unless gemdef.nil?
        end        
      end
      raise "#{name} has not been defined!"
    end
    
    # Allows you to chain method calls together. An important note is
    # that the <tt>*args</tt> are only passed into the first method in
    # the chain.
    # 
    # Example:
    #   Gemtronics.find_and_require_gem('gem1', :group => :production)
    # 
    # This will call the <tt>find</tt> method on Gemtronics::Manager
    # and pass it the arguments <tt>{:group => :production}</tt>. It will then
    # call the <tt>require_gem</tt> method on the Gemtronics::Definition class
    # returned by the <tt>find</tt> method.
    def method_missing(sym, *args)
      chain = sym.to_s.split('_and_')
      raise NoMethodError.new(sym.to_s) if chain.nil? || chain.empty? || chain.size == 1
      res = self.send(chain[0], *args)
      chain[1..chain.size].each do |meth|
        res = res.send(meth)
      end
      return res
    end
    
    def for_rails(config = nil, options = {})
      options = {:gemtronics_path => File.join(RAILS_ROOT, 'config', 'gemtronics.rb'),
                 :group => RAILS_ENV}.merge(options)
      [options.delete(:gemtronics_path)].flatten.each do |path|
        self.load(path)
      end
      group_list = [options.delete(:group)].flatten
      
      if config.nil?
        for_rails_without_config(group_list, options)
      else
        for_rails_with_config(group_list, config, options)
      end
      
    end
    
    private
    def for_rails_with_config(group_list, config, options = {})
      group_list.each do |group_name|
        group = self.groups[group_name.to_sym]
        group.gems.each do |gemdef|
          gemdef.require_list.each do |lib|
            gopts = {}
            gopts[:version] = gemdef.version unless gemdef.version == '>=0.0.0'
            gopts[:source] = gemdef.source unless gemdef.source == 'http://gems.rubyforge.org'
            gopts[:lib] = lib unless gemdef.name == lib
            gopts[:lib] = false unless gemdef.load?
            unless gopts.empty?
              config.gem(gemdef.name, gopts)
            else
              config.gem(gemdef.name)
            end
          end
        end
      end
    end
    
    def for_rails_without_config(group_list, options = {})
      Rails::Initializer.class_eval do
        alias_method :load_gems_without_gemtronics, :load_gems
        define_method(:load_gems_with_gemtronics) do
          group_list.each do |group_name|
            Gemtronics.require_gems(group_name)
          end
        end
        alias_method :load_gems, :load_gems_with_gemtronics
      end
    end
    
    def gem_installed?(gemdef) # :nodoc:
      return true if self.installed_gems.include?(gemdef.to_s)
      return gemdef.installed?
    end
    
  end # Manager
end # Gemtronics
