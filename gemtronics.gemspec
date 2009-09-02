# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gemtronics}
  s.version = "0.5.0.20090902161728"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["markbates"]
  s.date = %q{2009-09-02}
  s.default_executable = %q{gemtronics}
  s.description = %q{gemtronics was developed by: markbates}
  s.email = %q{}
  s.executables = ["gemtronics"]
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["lib/gemtronics/definition.rb", "lib/gemtronics/gemtronics.rb", "lib/gemtronics/grouper.rb", "lib/gemtronics/manager.rb", "lib/gemtronics.rb", "README", "LICENSE", "bin/gemtronics"]
  s.homepage = %q{}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{magrathea}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{gemtronics}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
