
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "minitest/smartdiff/version"

Gem::Specification.new do |spec|
  spec.name          = "minitest-smartdiff"
  spec.version       = Minitest::Smartdiff::VERSION
  spec.authors       = ["Stephen Prater", "Jeremy Cobb"]
  spec.email         = ["me@stephenprater.com"]

  spec.summary       = %q{Diffs are hard, make the robot do it.}
  spec.description   = %q{Diff between expected and actual with GPT}
  spec.homepage      = "https://github.com/stephenprater/minitest-smartdiff"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-openai", "~> 7.0"
  spec.add_dependency "xxhash", "~> 0.5"

  spec.add_development_dependency "bundler", "~> 2.5"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "debug", "~> 1.9"
end
