lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redstats/version'

Gem::Specification.new do |s|
  s.name = "redstats"
  s.version = RedStats::VERSION
  s.summary = %{Statistics counts and sums library using Redis.}
  s.description = %Q{RedStats is a library to track statistics using Redis database.}
  s.authors = ["qbazd"]
  s.email = ["jakub.zdroik@gmail.com"]
  s.license = "MIT"
  s.homepage = "https://github.com/qbazd/redstats"
  s.require_paths = ["lib"]
  s.files = `git ls-files`.split("\n")

  s.required_ruby_version = '>= 1.9.2'

  s.add_dependency "redis", '~> 3.2.1'
  s.add_dependency "nido", '~> 1.0.0'
  s.add_dependency 'activesupport', '~> 4.1'

  s.add_development_dependency "cutest", '~> 1.2.2'
  s.add_development_dependency 'timecop', '>= 0.5.9.1'
  s.add_development_dependency 'awesome_print', '>= 1.6.1'

end
