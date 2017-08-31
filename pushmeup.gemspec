# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'pushmeup/version'

Gem::Specification.new do |spec|
  spec.name            = 'pushmeup'
  spec.version         = Pushmeup::VERSION
  spec.authors         = ['Nicos Karalis']
  spec.email           = ['nicoskaralis@me.com']

  spec.homepage        = 'https://github.com/NicosKaralis/pushmeup'
  spec.summary         = %q{Send push notifications to Apple devices through ANPS and Android devices through GCM}
  spec.description     = <<-DESC
                        This gem is a wrapper to send push notifications to devices.
                        Currently it only sends to Android or iOS devices, but more platforms will be added soon.

                        With APNS (Apple Push Notifications Service) you can send push notifications to Apple devices.
                        With GCM (Google Cloud Messaging) you can send push notifications to Android devices.
                      DESC

  spec.rubyforge_project = 'pushmeup'

  spec.files             = `git ls-files`.split("\n")
  spec.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  spec.require_paths = %w(config lib)

  spec.add_dependency 'httparty'
  spec.add_dependency 'json'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
end
