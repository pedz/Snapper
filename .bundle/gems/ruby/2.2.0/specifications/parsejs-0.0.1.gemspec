# -*- encoding: utf-8 -*-
# stub: parsejs 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "parsejs"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Yehuda Katz"]
  s.date = "2015-06-26"
  s.description = "ParseJS is a JavaScript parser written using KPeg"
  s.email = ["wycats@gmail.com"]
  s.homepage = ""
  s.rubygems_version = "2.4.5.1"
  s.summary = "ParseJS parses JavaScript into a Ruby AST, suitable for preprocessing and other purposes. It also has work-in-progress support for extracting documentation from JavaScript"

  s.installed_by_version = "2.4.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<kpeg>, [">= 0"])
      s.add_runtime_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<uglifier>, [">= 0"])
      s.add_development_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<kpeg>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<uglifier>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<kpeg>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<uglifier>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
  end
end
