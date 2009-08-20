require File.dirname(__FILE__) + '/../spec_helper'

describe Gemtronics::Manager do
  
  describe 'find' do
    
    before(:each) do
      gemtronics.group(:default) do |g|
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
      Object.send(:remove_const, 'RAILS_ENV')
    end
    
    it 'should find a gem definition by group name' do
      gemtronics.find('gem2', :group => :development)
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
      gemtronics.should_receive(:gem).once.with('gem1', '>=0.0.0')
      gemtronics.should_receive(:require).once.with('gem1')
      gemtronics.group(:test) do |g|
        g.add('gem1')
        g.add('gem2', :load => false)
      end
      gemtronics.require_gems(:test)
    end
    
    it 'should handle Array based requires' do
      gemtronics.should_receive(:gem).once.with('gem1', '>=0.0.0')
      gemtronics.should_receive(:require).with('gem1')
      gemtronics.should_receive(:require).with('gem-one')
      gemtronics.group(:test) do |g|
        g.add('gem1', :require => ['gem1', 'gem-one'])
      end
      gemtronics.require_gems(:test)
    end
    
  end
  
  describe 'install_gems' do
    
    it 'should install the gems' do
      gemtronics.should_receive(:system).with('gem install gem3 --source=http://gems.rubyforge.org --version=4.5.6')
      gemtronics.should_receive(:system).with('gem install gem2 --source=http://gems.rubyforge.org')
      gemtronics.should_receive(:system).with('gem install gem1 --source=http://gems.example.org')
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
      gemtronics.should_receive(:system).with('gem install gem3 --source=http://gems.rubyforge.org --version=4.5.6')
      gemtronics.should_receive(:system).with('gem install gem2 --source=http://gems.rubyforge.org')
      gemtronics.should_receive(:system).with('gem install gem1 --source=http://gems.example.org')
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
  
end
