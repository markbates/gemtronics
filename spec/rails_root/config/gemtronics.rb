group(:default) do |g|
  g.add('gem1')
  g.add('gem2', :version => '1.2.3')
  g.add('gem3', :source => 'http://gems.github.com')
  g.add('gem4', :require => 'gem-four')
  g.add('gem5', :require => ['gem-five', 'gemfive'])
  g.add('gem6', :load => false)
end
 
group(:production, :dependencies => :default) do |g|
  g.add('gem3', :load => false)
  g.remove('gem1')
  g.add('gem4', :source => 'http://gems.example.org')
end
 
group(:development, :dependencies => :default) do |g|
  g.add('gem7', :version => '>=1.2.3.4', :load => false, :require => 'gemseven')
end
 
group(:test, :dependencies => :development, :source => 'http://gems.example.com') do |g|
  g.add('gem8')
end
 
group(:staging) do |g|
  g.add('gem2', :version => '3.2.1')
  g.dependency(:development)
  g.add('gem7', :load => true)
end