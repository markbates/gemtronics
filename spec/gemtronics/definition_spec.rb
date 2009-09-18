require File.dirname(__FILE__) + '/../spec_helper'

describe Gemtronics::Definition do
  
  before(:each) do
    @gd = Gemtronics::Definition.new
  end
  
  describe '<=>' do
    
    it 'should sort' do
      list = [gemdef('gem4', :version => '7.8.9', :update_version => '9.8.7'), 
              gemdef('Gem2', :version => '1.2.3', :update_version => '3.2.1')]
      list.sort!
      list[0].should == gemdef('gem2', :version => '1.2.3', :update_version => '3.2.1')
      list[1].should == gemdef('Gem4', :version => '7.8.9', :update_version => '9.8.7')
    end
    
  end
  
  describe 'has_update?' do
    
    it 'should return true/false if there is an update available' do
      @gd.name = 'gem1'
      @gd.version = '1.2.3'
      @gd.should_receive(:'`').with('gem list --remote ^gem1$').and_return(%{
*** REMOTE GEMS ***
gem1 (2.3.4, 9.9.9)})
      @gd.should have_update
      @gd.update_version.should == '2.3.4'
      
      @gd.should_receive(:'`').with('gem list --remote ^gem1$').and_return(%{
*** REMOTE GEMS ***
gem1 (1.2.3)})
      @gd.should_not have_update
      
      @gd.should_receive(:'`').with('gem list --remote ^gem1$').and_return(%{
*** REMOTE GEMS ***
gem1 (1.2.1)})
      @gd.should_not have_update
    end
    
    it 'should return false if there is an error' do
      @gd.name = 'gem1'
      @gd.version = '1.2.3'
      @gd.should_not have_update
    end
    
  end
  
  describe 'load_gem' do
    
    it 'should load the gem' do
      @gd.name = 'gem1'
      @gd.version = '1.2.3'
      @gd.should_receive(:gem).once.with('gem1', '1.2.3')
      @gd.load_gem
    end
    
  end
  
  describe 'require_gem' do
    
    it 'should require the files in the require_list' do
      @gd.name = 'gem1'
      @gd.require_list = ['file1', 'file2']
      @gd.should_receive(:gem).once.with('gem1', '>=0.0.0')
      @gd.should_receive(:require).with('file1')
      @gd.should_receive(:require).with('file2')
      @gd.require_gem
    end
    
  end
  
  describe 'to_s' do
    
    it 'should concat the name-version' do
      @gd.name = 'my_gem'
      @gd.version = '1.0.0'
      @gd.to_s.should == 'my_gem-1.0.0'
    end
    
  end
  
  describe 'install_command' do
    
    it 'should generate an install command string' do
      @gd.name = 'my_gem'
      @gd.install_command.should == 'gem install my_gem --no-ri --no-rdoc'
      @gd.version = '1.2.3'
      @gd.install_command.should == 'gem install my_gem --no-ri --no-rdoc --version=1.2.3'
      @gd.source = 'http://gems.example.org'
      @gd.install_command.should == 'gem install my_gem --source=http://gems.example.org --no-ri --no-rdoc --version=1.2.3'
      @gd.ri = true
      @gd.install_command.should == 'gem install my_gem --source=http://gems.example.org --no-rdoc --version=1.2.3'
      @gd.rdoc = true
      @gd.install_command.should == 'gem install my_gem --source=http://gems.example.org --version=1.2.3'
    end
    
  end
  
  describe 'installed?' do
    
    it 'should return true if the gem is installed' do
      @gd.should_receive(:gem).once.with('gem1', '1.2.3').and_return(true)
      @gd.name = 'gem1'
      @gd.version = '1.2.3'
      @gd.should be_installed
    end
    
    it 'should return false if the gem is not installed' do
      @gd.should_receive(:gem).once.with('gem1', '1.2.3').and_return {raise Gem::LoadError.new}
      @gd.name = 'gem1'
      @gd.version = '1.2.3'
      @gd.should_not be_installed
    end
    
  end
  
  def self.property(name, defval = nil, key = name)
    
    describe name do
      
      it "should return the #{name} property" do
        @gd[key] = 'foo'
        @gd.send(name).should == 'foo'
      end

      it "should set the #{name} property" do
        @gd.send("#{name.to_s.gsub('?', '')}=", 'bar')
        @gd.send(name).should == 'bar'
      end

      it "should return #{defval} if the #{name} property is not set" do
        @gd.send(name).should == defval
      end
      
    end
    
  end

  property(:name)
  property(:version, '>=0.0.0')
  property(:source, nil)
  property(:load?, true, :load)
  property(:ri?, false, :ri)
  property(:rdoc?, false, :rdoc)
  
  describe 'require_list' do
    
    it 'should return the require_list property' do
      @gd[:require] = 'foo'
      @gd.require_list.should == ['foo']
    end
    
    it 'should set the require_list property' do
      @gd.require_list = 'bar'
      @gd.require_list.should == ['bar']
    end
    
    it 'should return an array with the name of the gem if the property is not set' do
      @gd.name = 'gem1'
      @gd.require_list.should == ['gem1']
    end
    
  end
  
  describe 'new' do
    
    it 'should take a hash' do
      gd = Gemtronics::Definition[:name => 'gem1']
      gd.name.should == 'gem1'
    end
    
  end

  
end
