require File.dirname(__FILE__) + '/../spec_helper'

describe Gemtronics::Manager do
  
  describe 'find_out_of_date_gems' do
    
    it 'should return a list of outdated gems' do
      gemtronics.group(:default) do |g|
        g.add('gem1')
      end
      gemtronics.group(:production, :dependencies => :default) do |g|
        g.add('gem2', :version => '1.2.3')
      end
      gemtronics.group(:development, :dependencies => :default) do |g|
        g.add('gem3', :version => '4.5.6')
      end
      gemtronics.group(:test, :dependencies => :development) do |g|
        g.add('gem4', :version => '7.8.9')
      end
      gemtronics.find('gem1').should_receive(:has_update?).and_return(false)
      gemtronics.find('gem2').should_receive(:has_update?).and_return(gemdef('gem2', :version => '1.2.3', :update_version => '3.2.1'))
      gemtronics.find('gem3').should_receive(:has_update?).and_return(false)
      gemtronics.find('gem4').should_receive(:has_update?).and_return(gemdef('gem4', :version => '7.8.9', :update_version => '9.8.7'))
      list = gemtronics.find_out_of_date_gems
      list.size.should == 2
      list[0].should == gemdef('gem2', :version => '1.2.3', :update_version => '3.2.1')
      list[1].should == gemdef('gem4', :version => '7.8.9', :update_version => '9.8.7')
    end
    
  end
  
  describe 'alias_group' do
    
    before(:each) do
      gemtronics.group(:default) do |g|
        g.add('gem1')
      end
      gemtronics.alias_group(:development, :default)
      gemtronics.group(:test, :version => '1.2.3', :load => false, :dependencies => :development) do |g|
        g.add('gem2')
      end
      gemtronics.alias_group(:cucumber, :test)
    end
    
    it 'should inherit options from the aliased group' do
      gemdef = gemtronics.find('gem1', :group => :default)
      gemdef.version.should == '>=0.0.0'
      gemdef = gemtronics.find('gem2', :group => :test)
      gemdef.version.should == '1.2.3'
      gemdef = gemtronics.find('gem1', :group => :test)
      gemdef.version.should == '>=0.0.0'
      gemdef = gemtronics.find('gem2', :group => :cucumber)
      gemdef.version.should == '1.2.3'
      gemdef = gemtronics.find('gem1', :group => :cucumber)
      gemdef.version.should == '>=0.0.0'
    end
    
  end
  
  describe 'find' do
    
    before(:each) do
      gemtronics.group(:default, :source => 'http://gems.github.com') do |g|
        g.add('gem1')
      end
      gemtronics.group(:production, :dependencies => :default) do |g|
        g.add('gem2', :version => '1.2.3')
      end
      gemtronics.group(:development, :dependencies => :default) do |g|
        g.add('gem2', :version => '4.5.6')
      end
      gemtronics.group(:test, :dependencies => :development) do |g|
        g.add('gem3', :version => '7.8.9')
      end
    end
    
    it 'should find a gem definition by RAILS_ENV' do
      RAILS_ENV = 'development'
      gemdef = gemtronics.find('gem2')
      gemdef.version.should == '4.5.6'
      gemdef.source.should == 'http://gems.github.com'
      Object.send(:remove_const, 'RAILS_ENV')
    end
    
    it 'should find a gem definition by group name' do
      gemdef = gemtronics.find('gem2', :group => :development)
      gemdef.version.should == '4.5.6'
      gemdef = gemtronics.find('gem2', :group => :production)
      gemdef.version.should == '1.2.3'
    end
    
    it 'should find the gem definition by group name before RAILS_ENV' do
      RAILS_ENV = 'production'
      gemdef = gemtronics.find('gem2', :group => :development)
      gemdef.version.should == '4.5.6'
      Object.send(:remove_const, 'RAILS_ENV')
    end
    
    it 'should find a gem definition' do
      gemdef = gemtronics.find('gem2')
      gemdef.name.should == 'gem2'
    end
    
    it 'should raise an error if the gem does not exist' do
      lambda {
        gemtronics.find('unknowngem')
      }.should raise_error('unknowngem has not been defined!')
    end
    
  end
  
  describe 'method_missing' do
    
    it' should try and chain methods based on _and_' do
      gemdef = mock('gem1')
      gemdef.should_receive(:require_gem)
      gemtronics.should_receive(:find).with('gem1').and_return(gemdef)
      gemtronics.find_and_require_gem('gem1')
    end
    
    it 'should call super if not a chained method call' do
      lambda {
        gemtronics.foo_bar
      }.should raise_error(NoMethodError)
    end
    
  end
  
  describe 'group' do
    
    it 'should yield a Grouper class' do
      lambda {
        gemtronics.group(:default) do |g|
          g.should be_kind_of(Gemtronics::Grouper)
          raise BlockRan
        end
      }.should raise_error(BlockRan)
    end
    
  end
  
  describe 'require_gems' do
    
    it 'should only require gems that have load set to true' do
      gemtronics.group(:test) do |g|
        g.add('gem1')
        g.add('gem2', :load => false)
      end
      gemtronics.group(:test).search('gem1').should_receive(:gem).once.with('gem1', '>=0.0.0')
      gemtronics.group(:test).search('gem1').should_receive(:require).once.with('gem1')
      gemtronics.require_gems(:test)
    end
    
    it 'should handle Array based requires' do
      gemtronics.group(:test) do |g|
        g.add('gem1', :require => ['gem1', 'gem-one'])
      end
      gemtronics.group(:test).search('gem1').should_receive(:gem).once.with('gem1', '>=0.0.0')
      gemtronics.group(:test).search('gem1').should_receive(:require).with('gem1')
      gemtronics.group(:test).search('gem1').should_receive(:require).with('gem-one')
      gemtronics.require_gems(:test)
    end
    
  end
  
  describe 'install_gems' do
    
    it 'should install the gems' do
      gemtronics.should_receive(:system).with('gem install gem3 --no-ri --no-rdoc --version=4.5.6')
      gemtronics.should_receive(:system).with('gem install gem2 --no-ri --no-rdoc')
      gemtronics.should_receive(:system).with('gem install gem1 --source=http://gems.example.org --no-ri --no-rdoc')
      gemtronics.group(:test) do |g|
        g.add('gem1', :source => 'http://gems.example.org')
        g.add('gem2', :version => '>=1.2.3')
        g.add('gem3', :version => '4.5.6')
      end
      gemtronics.install_gems(:test)
    end
    
    it 'should not install already installed gems' do
      gemtronics.should_receive(:gem_installed?).with(gemdef('gem1', :source => 'http://gems.example.org')).and_return(false)
      gemtronics.should_receive(:gem_installed?).with(gemdef('gem2', :version => '>=1.2.3')).and_return(false)
      gemtronics.should_receive(:gem_installed?).with(gemdef('gem3', :version => '4.5.6')).and_return(false)
      gemtronics.should_receive(:gem_installed?).with(gemdef('gem4')).and_return(true)
      gemtronics.should_receive(:system).with('gem install gem3 --no-ri --no-rdoc --version=4.5.6')
      gemtronics.should_receive(:system).with('gem install gem2 --no-ri --no-rdoc')
      gemtronics.should_receive(:system).with('gem install gem1 --source=http://gems.example.org --no-ri --no-rdoc')
      gemtronics.group(:test) do |g|
        g.add('gem1', :source => 'http://gems.example.org')
        g.add('gem2', :version => '>=1.2.3')
        g.add('gem3', :version => '4.5.6')
        g.add('gem4')
      end
      gemtronics.install_gems(:test)
    end
    
    it 'should install all gems if passed the everything! group' do
      gemtronics.group(:foo)
      gemtronics.group(:bar)
      gemtronics.should_receive(:install_all_gems)
      gemtronics.install_gems('everything!')
    end
    
  end
  
  describe 'load' do
    
    it 'should load a file' do
      gemtronics.load(fixture_path('sample.gems'))
      groups = gemtronics.groups
      groups.size.should == 5
      
      default = groups[:default]
      default.gems.should == [
        gemdef('gem1'),
        gemdef('gem2', :version => '1.2.3'),
        gemdef('gem3', :source => 'http://gems.github.com'),
        gemdef('gem4', :require => 'gem-four'),
        gemdef('gem5', :require => ["gem-five", "gemfive"]),
        gemdef('gem6', :load => false)
      ]
      
      staging = groups[:staging]
      staging.gems.should == [
        gemdef('gem2', :version => '1.2.3'),
        gemdef('gem1'),
        gemdef('gem3', :source => 'http://gems.github.com'), 
        gemdef('gem4', :require => 'gem-four'), 
        gemdef('gem5', :require => ["gem-five", "gemfive"]),
        gemdef('gem6', :load => false),
        gemdef('gem7', :version => ">=1.2.3.4", :require => 'gemseven')
      ]
      
    end
    
  end
  
  describe 'for_rails' do
    
    before(:each) do
      RAILS_ENV = 'test'
      RAILS_ROOT = File.join(File.dirname(__FILE__), '..', 'rails_root')
    end
    
    after(:each) do
      Object.send(:remove_const, 'RAILS_ENV')
      Object.send(:remove_const, 'RAILS_ROOT')
    end
    
    it 'should call the config.gem method correctly' do
      config = mock('Rails.configuration')
      config.should_receive(:gem).with('gem1', :source => 'http://gems.example.com')
      config.should_receive(:gem).with("gem6", :lib => false, :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem4', :lib => 'gem-four', :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem2', :version => '1.2.3', :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem3', :source => 'http://gems.github.com')
      config.should_receive(:gem).with('gem5', :lib => 'gemfive', :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem5', :lib => 'gem-five', :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem7', :version => '>=1.2.3.4', :lib => false, :source => 'http://gems.example.com')
      config.should_receive(:gem).with('gem8', :source => 'http://gems.example.com')
      gemtronics.for_rails(config)
    end
    
    it 'should just require the gems if no config is given' do
      Rails::Initializer.should_receive(:alias_method).with(:load_gems_without_gemtronics, :load_gems)
      Rails::Initializer.should_receive(:define_method).with(:load_gems_with_gemtronics)
      Rails::Initializer.should_receive(:alias_method).with(:load_gems, :load_gems_with_gemtronics)
      gemtronics.for_rails
    end
    
  end
  
end
