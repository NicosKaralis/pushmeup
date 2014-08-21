# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pushmeup/version"

Gem::Specification.new do |s|
  s.name            = 'pushmeup'
  s.version         = Pushmeup::VERSION
  s.authors         = ["Nicos Karalis", "Pedro Piñera"]
  s.email           = ["pepibumur@gmail.com"]
  
  s.homepage        = "https://github.com/teambox/pushmeup"
  s.summary         = %q{Send push notifications to Apple devices through ANPS and Android devices through GCM}
  s.description     = <<-DESC
                        This gem is a wrapper to send push notifications to devices.
                        Currently it only sends to Android or iOS devices, but more platforms will be added soon.

                        With APNS (Apple Push Notifications Service) you can send push notifications to Apple devices.
                        With GCM (Google Cloud Messaging) you can send push notifications to Android devices.
                      DESC

  s.rubyforge_project = "pushmeup"
  
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]

  s.add_dependency 'httparty'
  s.add_dependency 'json'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end