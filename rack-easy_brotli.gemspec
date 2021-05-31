require_relative 'lib/rack/brotli/version'

Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name    = 'rack-easy_brotli'
  s.version = Rack::Brotli::Version.to_s
  s.date    = Time.now.strftime("%F")

  s.licenses = ['MIT']

  s.description = "Rack::Brotli enables Google's Brotli compression on HTTP responses"
  s.summary     = "Brotli compression for Rack responses"

  s.authors = ["Marco Costa"]
  s.email = "marco@marcotc.com"

  # = MANIFEST =
  s.files = %w[
    COPYING
    README.md
  ] + `git ls-files -z lib`.split("\0")

  s.test_files = s.files.select {|path| path =~ /^test\/.*\_spec.rb/}

  s.extra_rdoc_files = %w[README.md COPYING]

  s.required_ruby_version = '>= 2.5.0'

  s.add_dependency 'rack', '>= 2.1.0'
  s.add_dependency 'brotli', '>= 0.4.0'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest', '~> 5.14.4'
  s.add_development_dependency 'rake', '~> 13.0.3'
  s.add_development_dependency 'rdoc', '~> 6.3.1'

  s.homepage = "http://github.com/marcotc/rack-brotli/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "rack-brotli", "--main", "README"]
  s.require_paths = %w[lib]
  s.rubygems_version = '0.1.0'
end
