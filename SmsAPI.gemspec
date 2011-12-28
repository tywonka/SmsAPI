# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "SmsAPI/version"

Gem::Specification.new do |s|
  s.name        = "SmsAPI"
  s.version     = SmsAPI::VERSION
  s.authors     = ["Alex Lysenko"]
  s.email       = ["tywonka@gmail.com"]
  s.homepage    = ""
  s.summary     = "SMS API to sms16.ru"
  s.description = "SMS API to sms16.ru"

  s.rubyforge_project = "SmsAPI"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
