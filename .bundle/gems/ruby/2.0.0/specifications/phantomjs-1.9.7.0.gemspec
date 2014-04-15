# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "phantomjs"
  s.version = "1.9.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christoph Olszowka"]
  s.date = "2014-02-26"
  s.description = "Auto-install phantomjs on demand for current platform. Comes with poltergeist integration."
  s.email = ["christoph at olszowka.de"]
  s.homepage = "https://github.com/colszowka/phantomjs-gem"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Auto-install phantomjs on demand for current platform. Comes with poltergeist integration."

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<poltergeist>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 2.11.0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<poltergeist>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 2.11.0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<poltergeist>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 2.11.0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
