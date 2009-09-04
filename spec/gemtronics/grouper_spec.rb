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
    group.gems.should == [gemdef('gem1', :source => 'http://gems.example.org'), gemdef('gem2', :source => "http://gems.example.org")]
  end
  
  describe 'search' do
    
    before(:each) do
      gemtronics.group(:test) do |g|
        g.add('gem1', :version => '1.2.3')
      end
    end
    
    it 'should return the defintion if the gem is defined' do
      gemdef = gemtronics.group(:test).search('gem1')
      gemdef.version.should == '1.2.3'
    end
    
    it 'should return nil if the gem is not defined' do
      gemdef = gemtronics.group(:test).search('gem2')
      gemdef.should be_nil
    end
    
  end
  
  describe 'add' do
    
    it 'should add a gem to the list, and inherit the global options' do
      gemtronics.group(:test) do |g|
        g.add('gem1')
      end
      group = gemtronics.groups[:test]
      group.should be_kind_of(Gemtronics::Grouper)
      gm = group.gems.first
      gm.should == gemdef('gem1')
    end
    
    it 'should inherit the groups options' do
      gemtronics.group(:test2, :source => 'http://gems.example.org') do |g|
        g.add('gem2')
      end
      
      group = gemtronics.groups[:test2]
      
      gm = group.gems.first
      gm.should == gemdef('gem2', :source => "http://gems.example.org")
    end
    
    it 'should merge in the new definition if add is called again' do
      gemtronics.group(:test) do |g|
        g.add('gem1', :version => '1.2.3')
      end
      group = gemtronics.groups[:test]
      group.gems.size.should == 1
      gm = group.gems.first
      gm.should == gemdef('gem1', :version => '1.2.3')
      gemtronics.group(:test) do |g|
        g.add('gem1', :version => '3.2.1')
      end
      group = gemtronics.groups[:test]
      group.gems.size.should == 1
      gm = group.gems.first
      gm.should == gemdef('gem1', :version => '3.2.1')
    end
    
    it 'should add the gem to the dependencies of the group' do
      gemtronics.group(:grp1) do |g|
        g.add('gem1')
      end
      gemtronics.group(:grp2, :dependencies => :grp1) do |g|
        g.add('gem2')
      end
      gemtronics.group(:grp1) do |g|
        g.add('gem3')
      end
      group = gemtronics.groups[:grp2]
      group.gems.size.should == 3
      group.gems[2].should == gemdef('gem3')
    end
    
  end
  
  describe 'remove' do
    
    it 'should remove a gem from the list' do
      gemtronics.group(:test) do |g|
        g.add('gem1')
        g.add('gem2')
      end
      gemtronics.groups[:test].gems.should == [gemdef('gem1'), gemdef('gem2')]
      
      gemtronics.group(:test) do |g|
        g.remove('gem1')
      end
      
      gemtronics.groups[:test].gems.should == [gemdef('gem2')]
    end
    
  end
  
end
