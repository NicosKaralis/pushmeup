# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pushmeup/version"

Gem::Specification.new do |s|
  s.name            = 'pushmeup'
  s.version         = Pushmeup::VERSION
  s.authors         = ["Nicos Karalis"]
  s.email           = ["nicoskaralis@me.com"]
  
  s.homepage        = ""
  s.summary         = %q{TODO: Write a gem summary}
  s.description     = <<-DESC
                        Write a gem description
                      DESC

  s.rubyforge_project = "pushmeup"
  
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]

  s.add_dependency('httparty')
  s.add_dependency('json')

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
