require 'singleton'
Dir.glob(File.join(File.dirname(__FILE__), 'gemtronics', '**/*.rb')).each do |f|
  require File.expand_path(f)
end
