require File.dirname(__FILE__) + '/../spec_helper'

describe Gemtronics::Definition do
  
  before(:each) do
    @gd = Gemtronics::Definition.new
  end
  
  describe 'name' do
    
    it 'should return the name property' do
      @gd[:name] = 'foo'
      @gd.name.should == 'foo'
    end
    
    it 'should set the name property' do
      @gd.name = 'bar'
      @gd.name.should == 'bar'
    end
    
  end
  
  describe 'load' do
    
    it 'should return the load property' do
      @gd[:load] = true
      @gd.load.should be_true
    end
    
    it 'should set the load property' do
      @gd.load = false
      @gd.load.should be_false
    end
    
  end
  
  describe 'version' do
    
    it 'should return the version property' do
      @gd[:version] = 'foo'
      @gd.version.should == 'foo'
    end
    
    it 'should set the version property' do
      @gd.version = 'bar'
      @gd.version.should == 'bar'
    end
    
  end
  
  describe 'require_list' do
    
    it 'should return the require_list property' do
      @gd[:require] = 'foo'
      @gd.require_list.should == 'foo'
    end
    
    it 'should set the require_list property' do
      @gd.require_list = 'bar'
      @gd.require_list.should == 'bar'
    end
    
  end
  
  describe 'source' do
    
    it 'should return the source property' do
      @gd[:source] = 'foo'
      @gd.source.should == 'foo'
    end
    
    it 'should set the source property' do
      @gd.source = 'bar'
      @gd.source.should == 'bar'
    end
    
  end
  
end
