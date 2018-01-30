require File.dirname(__FILE__) + "/lib/knife-okta"

Gem::Specification.new do |spec|
  spec.name          = "knife-okta"
  spec.version       = KnifeOkta::VERSION
  spec.authors       = ["Stephen Hoekstra"]
  spec.email         = ["shoekstra@schubergphilis.com"]

  spec.description   = %q{A knife plugin to interact with the Okta API.}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/shoekstra/knife-okta"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w{lib}

  spec.add_dependency "chef", ">= 12.0"
  spec.add_dependency "oktakit", "~> 0.2.0"
end
