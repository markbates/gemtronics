require File.dirname(__FILE__) + '/../spec_helper'

describe Gemtronics::Grouper do
  
  it 'should add dependencies' do
    gemtronics.group(:test) do |g|
      g.add('gem1')
    end
    gemtronics.group(:test2, :source => 'http://gems.example.org', :dependencies => :test) do |g|
      g.add('gem2')
    end
    group = gemtronics.groups[:test2]
    group.gems.should == [{:source => "http://gems.rubyforge.org", :load => true, :version => ">=0.0.0", :require => ["gem1"], :name => "gem1"}, {:source => "http://gems.example.org", :load => true, :version => ">=0.0.0", :require => ["gem2"], :name => "gem2"}]
  end
  
  describe 'add' do
    
    it 'should add a gem to the list, and inherit the global options' do
      gemtronics.group(:test) do |g|
        g.add('gem1')
      end
      group = gemtronics.groups[:test]
      group.should be_kind_of(Gemtronics::Grouper)
      gm = group.gems.first
      gm.should == {:source => "http://gems.rubyforge.org", :load => true, :version => ">=0.0.0", :require => ["gem1"], :name => "gem1"}
    end
    
    it 'should inherit the groups options' do
      gemtronics.group(:test2, :source => 'http://gems.example.org') do |g|
        g.add('gem2')
      end
      
      group = gemtronics.groups[:test2]
      
      gm = group.gems.first
      gm.should == {:source => "http://gems.example.org", :load => true, :version => ">=0.0.0", :require => ["gem2"], :name => "gem2"}
    end
    
    it 'should merge in the new definition if add is called again' do
      gemtronics.group(:test) do |g|
        g.add('gem1', :version => '1.2.3')
      end
      group = gemtronics.groups[:test]
      group.gems.size.should == 1
      gm = group.gems.first
      gm.should == {:source => "http://gems.rubyforge.org", :load => true, :version => "1.2.3", :require => ["gem1"], :name => "gem1"}
      gemtronics.group(:test) do |g|
        g.add('gem1', :version => '3.2.1')
      end
      group = gemtronics.groups[:test]
      group.gems.size.should == 1
      gm = group.gems.first
      gm.should == {:source => "http://gems.rubyforge.org", :load => true, :version => "3.2.1", :require => ["gem1"], :name => "gem1"}
    end
    
  end
  
  describe 'remove' do
    
    it 'should remove a gem from the list' do
      gemtronics.group(:test) do |g|
        g.add('gem1')
        g.add('gem2')
      end
      gemtronics.groups[:test].gems.should == [{:source => "http://gems.rubyforge.org", :load => true, :version => ">=0.0.0", :require => ["gem1"], :name => "gem1"}, {:source => "http://gems.rubyforge.org", :load => true, :version => ">=0.0.0", :require => ["gem2"], :name => "gem2"}]
      
      gemtronics.group(:test) do |g|
        g.remove('gem1')
      end
      
      gemtronics.groups[:test].gems.should == [{:source => "http://gems.rubyforge.org", :load => true, :version => ">=0.0.0", :require => ["gem2"], :name => "gem2"}]
    end
    
  end
  
end
