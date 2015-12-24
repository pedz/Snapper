# -*- encoding: utf-8 -*-
# stub: yard-rspec 0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "yard-rspec"
  s.version = "0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Loren Segal"]
  s.date = "2009-09-14"
  s.email = "lsegal@soen.ca"
  s.homepage = "http://yardoc.org"
  s.rubyforge_project = "yard-rspec"
  s.rubygems_version = "2.4.5.1"
  s.summary = "YARD plugin to list RSpec specifications inside documentation"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yard>, [">= 0"])
    else
      s.add_dependency(%q<yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<yard>, [">= 0"])
  end
end
