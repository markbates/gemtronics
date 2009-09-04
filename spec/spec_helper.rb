require 'rubygems'
require 'spec'

require File.join(File.dirname(__FILE__), '..', 'lib', 'gemtronics')

Spec::Runner.configure do |config|
  
  config.before(:all) do
    
  end
  
  config.after(:all) do
    
  end
  
  config.before(:each) do
    gemtronics.reset!
  end
  
  config.after(:each) do
    gemtronics.reset!
  end
  
end

def gemtronics(*args)
  Gemtronics::Manager.instance
end

class BlockRan < StandardError
end

def fixture_path(*args)
  return File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', *args))
end

def fixture_value(*args)
  File.read(fixture_path(*args))
end

def gemdef(name, options = {})
  gemdef = Gemtronics::Definition[{:name => name, :require => [name], :version => '>=0.0.0', :load => true, :ri => false, :rdoc => false}.merge(options)]
  return gemdef
end

module Rails
  class Initializer
    
    def load_gems
    end
    
  end
end