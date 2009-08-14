module Gemtronics
  # This class is yielded up when you create/modify a group.
  # This class holds all the relevant information about the gems
  # for the defined group.
  # 
  # See Gemtronics::Manager for more details on creating a group.
  class Grouper
    # The name of this group
    attr_accessor :name
    # The Array of gems belonging to this group.
    attr_accessor :gems
    # A Hash representing the default options for this group.
    attr_accessor :group_options
    # An Array containing the names of the dependents of this group.
    attr_accessor :dependents
    
    # Creates a new Gemtronics::Grouper class. It takes a Hash
    # of options that will be applied to all gems added to the group.
    # These options will be merged with Gemtronics::Manager::GLOBAL_DEFAULT_OPTIONS
    # 
    # This also takes a special option <tt>:dependencies</tt> which can
    # be an Array of other groups to inherit gems from.
    # 
    # Example:
    #   group(:development) do |g|
    #     g.add('gem1')
    #   end
    # 
    #   group(:test, :dependencies => :development) do |g|
    #     g.add('gem2')
    #     g.add('gem3')
    #   end
    # 
    # In this example the <tt>:test</tt> group would
    # now have the following gems: <tt>gem1, gem2, gem3</tt>
    def initialize(name, options = {})
      self.name = name
      self.gems = []
      self.dependents = []
      options = {} if options.nil?
      self.group_options = Gemtronics::Manager::GLOBAL_DEFAULT_OPTIONS.merge(options)
      deps = self.group_options.delete(:dependencies)
      if deps
        [deps].flatten.each do |dep|
          self.dependency(dep)
        end
      end
      self
    end
    
    # Adds a gem to the group. All that is required is the name of the gem.
    # 
    # The following is a list of the options that can be passed in:
    #   :require # a String or Array of file(s) to be required by the system
    #   :version # a String representing the version number of the gem.
    #   :source # a String representing the source URL of where the gem lives
    #   :load # true/false the files specified by the :require option should be loaded
    # 
    # These options get merged with the group options and the global options.
    # 
    # Example:
    #   group(:default, :version => '>=1.0.0') do |g|
    #     g.add('gem1', :source => 'http://gems.example.com')
    #     g.add('gem2', :version => '0.9.8')
    #     g.add('gem3', :require => ['gem-three', 'gem3'], :version => '>2.0.0')
    #     g.add('gem4', :require => 'gemfour', :load => false)
    #   end
    # 
    #   # => [{:name => 'gem1', :version => '>=1.0.0', :source => 'http://gems.example.com', 
    #          :require => ['gem1'], :load => true},
    #         {:name => 'gem2', :version => '0.9.8', :source => 'http://gems.rubyforge.org', 
    #          :require => ['gem2'], :load => true},
    #         {:name => 'gem3', :version => '>2.0.0', :source => 'http://gems.rubyforge.org', 
    #          :require => ['gem-three', 'gem3'], :load => true},
    #         {:name => 'gem4', :version => '>=1.0.0', :source => 'http://gems.rubyforge.org', 
    #          :require => ['gemfour']}, :load => false]
    def add(name, options = {})
      name = name.to_s
      ind = self.gems.size
      g = {}
      self.gems.each_with_index do |gemdef, i|
        if gemdef[:name] == name
          g = gemdef
          ind = i
          break
        end
      end

      g = self.group_options.merge({:name => name, :require => [name]}.merge(g).merge(options))
      g[:require] = [g[:require]].flatten
      self.gems[ind] = g
      self.dependents.each do |dep|
        Gemtronics.group(dep).add(name, options)
      end
    end
    
    # Removes a gem from the group.
    # 
    # Example:
    #   group(:development) do |g|
    #     g.add('gem1')
    #     g.add('gem2')
    #   end
    # 
    #   group(:test, :dependencies => :development) do |g|
    #     g.add('gem3')
    #     g.remove('gem2')
    #     g.add('gem4')
    #   end
    # 
    # In this example the <tt>:test</tt> group would
    # now have the following gems: <tt>gem1, gem3, gem4</tt>
    def remove(name)
      self.gems.each do |g|
        if g[:name] = name.to_s
          self.gems.delete(g)
          break
        end
      end
    end
    
    # Injects another groups gems into this group.
    # 
    # Example:
    #   group(:development) do |g|
    #     g.add('gem1')
    #   end
    # 
    #   group(:test) do |g|
    #     g.add('gem2')
    #     g.dependency(:development)
    #     g.add('gem3')
    #   end
    # 
    # In this example the <tt>:test</tt> group would
    # now have the following gems: <tt>gem2, gem1, gem3</tt>
    def dependency(name)
      group = Gemtronics::Manager.instance.groups[name.to_sym]
      if group
        Gemtronics.group(name.to_sym).dependents << self.name
        group.gems.dup.each do |gemdef|
          self.add(gemdef[:name], gemdef)
        end
      end
    end
    
  end # Grouper
end # Gemtronics
